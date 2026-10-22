package com.englishspeaking.ai.ai;

import com.englishspeaking.ai.common.error.ApiException;
import com.englishspeaking.ai.config.AppProperties;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.util.UUID;

@Service
public class LiveAccessService {
    @org.springframework.beans.factory.annotation.Autowired(required=false)
    private com.englishspeaking.ai.learning.LearningService learning;
    private final LiveTokenProvider provider;
    private final JdbcTemplate jdbc;
    private final AppProperties properties;
    public LiveAccessService(LiveTokenProvider provider, JdbcTemplate jdbc, AppProperties properties) {
        this.provider = provider; this.jdbc = jdbc; this.properties = properties;
    }
    @Transactional
    public LiveTokenProvider.Ticket issue(UUID user, String voice, String level) {
        if (!provider.configured()) throw new ApiException("AI_NOT_CONFIGURED",
            "Chưa cấu hình Gemini. Hãy điền GEMINI_API_KEY trên máy chủ.", HttpStatus.SERVICE_UNAVAILABLE);
        jdbc.execute((org.springframework.jdbc.core.ConnectionCallback<Void>) connection -> {
            if ("PostgreSQL".equals(connection.getMetaData().getDatabaseProductName())) {
                try (var s = connection.prepareStatement("select pg_advisory_xact_lock(?)")) {
                    s.setLong(1, user.getMostSignificantBits() ^ user.getLeastSignificantBits()); s.execute();
                }
            }
            return null;
        });
        var day = LocalDate.now(ZoneOffset.UTC);
        Integer reserved = jdbc.queryForObject(
            "select coalesce(sum(reserved_seconds),0) from live_voice_access where user_id=? and usage_day=?", Integer.class, user, day);
        if ((reserved == null ? 0 : reserved) + 300 > properties.getQuota().getDefaultDailyMinutes() * 60)
            throw new ApiException("QUOTA_EXCEEDED", "Đã hết lượt gọi hôm nay. Mỗi phiên được cấp tối đa 5 phút.", HttpStatus.TOO_MANY_REQUESTS);
        var pref = learning == null ? null : learning.preference(user);
        var profileContext = learning == null ? "" : learning.tutorContext(user);
        var ticket = learning == null ? provider.issue(voice,level) : provider.issue(voice, level, profileContext);
        UUID sessionId=UUID.randomUUID();
        jdbc.update("insert into live_voice_access(id,user_id,usage_day,reserved_seconds,issued_at) values(?,?,?,?,?)",
            sessionId, user, day, 300, java.sql.Timestamp.from(Instant.now()));
        return new LiveTokenProvider.Ticket(ticket.token(),ticket.model(),ticket.voice(),ticket.expiresAt(),ticket.maxSeconds(),ticket.setup(),sessionId,pref != null && pref.enabled && pref.saveVoiceTranscripts);
    }
}
