package com.englishspeaking.ai.conversation.service;

import com.englishspeaking.ai.common.error.ApiException;
import com.englishspeaking.ai.conversation.domain.FeedbackEntity;
import com.englishspeaking.ai.conversation.domain.IdempotencyRecord;
import com.englishspeaking.ai.conversation.domain.MessageEntity;
import com.englishspeaking.ai.conversation.domain.SessionEntity;
import com.englishspeaking.ai.conversation.dto.*;
import com.englishspeaking.ai.conversation.repository.FeedbackRepository;
import com.englishspeaking.ai.conversation.repository.IdempotencyRepository;
import com.englishspeaking.ai.conversation.repository.MessageRepository;
import com.englishspeaking.ai.conversation.repository.SessionRepository;
import com.englishspeaking.ai.curriculum.model.Scenario;
import com.englishspeaking.ai.curriculum.repository.ScenarioRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.time.Instant;
import java.util.*;

@Service
public class SessionService {

    private static final Logger log = LoggerFactory.getLogger(SessionService.class);
    private static final Set<String> VALID_MODES = Set.of("text", "guided", "realtime");
    private static final ThreadLocal<MessageDigest> SHA_256 = ThreadLocal.withInitial(() -> {
        try {
            return MessageDigest.getInstance("SHA-256");
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 algorithm not available", e);
        }
    });

    @org.springframework.beans.factory.annotation.Autowired
    private com.englishspeaking.ai.learning.LearningService learning;

    private final SessionRepository sessionRepository;
    private final MessageRepository messageRepository;
    private final FeedbackRepository feedbackRepository;
    private final IdempotencyRepository idempotencyRepository;
    private final ScenarioRepository scenarioRepository;
    private final ConversationAiService aiService;
    private final ObjectMapper objectMapper;
    private final org.springframework.jdbc.core.JdbcTemplate jdbc;
    private final com.englishspeaking.ai.config.AppProperties properties;

    public SessionService(
            SessionRepository sessionRepository,
            MessageRepository messageRepository,
            FeedbackRepository feedbackRepository,
            IdempotencyRepository idempotencyRepository,
            ScenarioRepository scenarioRepository,
            ConversationAiService aiService,
            ObjectMapper objectMapper,
            org.springframework.jdbc.core.JdbcTemplate jdbc,
            com.englishspeaking.ai.config.AppProperties properties
    ) {
        this.sessionRepository = sessionRepository;
        this.messageRepository = messageRepository;
        this.feedbackRepository = feedbackRepository;
        this.idempotencyRepository = idempotencyRepository;
        this.scenarioRepository = scenarioRepository;
        this.aiService = aiService;
        this.objectMapper = objectMapper;
        this.jdbc = jdbc;
        this.properties = properties;
    }

    @Transactional
    public SessionResponse createSession(UUID userId, String idempotencyKey, SessionCreateRequest req) {
        validateIdempotencyKey(idempotencyKey);
        lockUser(userId);
        String reqHash = hashString(req != null ? req.toString() : "");
        idempotencyKey = hashString("POST:/sessions:" + idempotencyKey);

        Optional<IdempotencyRecord> existing = idempotencyRepository.findByUserIdAndKey(userId, idempotencyKey);
        if (existing.isPresent()) {
            IdempotencyRecord record = existing.get();
            if (!record.getRequestHash().equals(reqHash)) {
                throw new ApiException("CONFLICT", "Idempotency key reused with different request payload", HttpStatus.CONFLICT);
            }
            try {
                return objectMapper.readValue(record.getResponseBody(), SessionResponse.class);
            } catch (JsonProcessingException e) {
                throw new ApiException("IDEMPOTENCY_STATE_UNAVAILABLE", "Không thể khôi phục kết quả cũ. Không gửi thêm yêu cầu mới.", HttpStatus.SERVICE_UNAVAILABLE);
            }
        }

        if (req == null || req.mode() == null || !VALID_MODES.contains(req.mode().toLowerCase())) {
            throw new ApiException("VALIDATION_FAILED", "Mode must be one of: text, guided, realtime", HttpStatus.BAD_REQUEST);
        }

        if (!"text".equalsIgnoreCase(req.mode())) {
            throw new ApiException("MODE_UNAVAILABLE", "Chế độ âm thanh chưa được tích hợp.", HttpStatus.SERVICE_UNAVAILABLE);
        }
        if (req.level() != null && !Set.of("A0", "A1", "A2", "B1", "B2", "C1", "C2").contains(req.level())) {
            throw new ApiException("VALIDATION_FAILED", "Invalid level", HttpStatus.BAD_REQUEST);
        }
        Scenario scenario = null;
        if (req.scenarioId() != null) {
            scenario = scenarioRepository.findById(req.scenarioId())
                    .filter(Scenario::isActive)
                    .orElseThrow(() -> new ApiException("NOT_FOUND", "Scenario not found", HttpStatus.NOT_FOUND));
        }

        SessionEntity session = new SessionEntity(userId, req.scenarioId(), req.mode().toLowerCase(java.util.Locale.ROOT), req.level());
        session = sessionRepository.save(session);

        List<MessageResponse> messages = new ArrayList<>();
        // If guided/text scenario has a starter prompt from AI, seed the initial message
        if (scenario != null && scenario.getRoleAi() != null) {
            String initialText = String.format("Hello! I am your %s for today's scenario \"%s\". How would you like to start?",
                    scenario.getRoleAi(), scenario.getTitle());
            String samplePhrasesJson = scenario.getSamplePhrases() != null && !scenario.getSamplePhrases().isBlank()
                    ? scenario.getSamplePhrases()
                    : "[\"Let's begin!\"]";
            MessageEntity firstAiMsg = new MessageEntity(
                    session.getId(),
                    "ai",
                    initialText,
                    1,
                    samplePhrasesJson,
                    toJson(List.of("I am ready to begin.", "Could you explain our scenario goals?"))
            );
            firstAiMsg = messageRepository.save(firstAiMsg);
            messages.add(mapMessage(firstAiMsg));
        }

        SessionResponse response = mapSession(session, messages);
        saveIdempotency(userId, idempotencyKey, "POST", "/api/v1/sessions", reqHash, 201, response);
        return response;
    }

    @Transactional(readOnly = true)
    public PaginatedSessionsResponse getUserSessions(UUID userId, int page, int size) {
        if (page < 0) {
            throw new ApiException("VALIDATION_FAILED", "page must be >= 0", HttpStatus.BAD_REQUEST);
        }
        if (size < 1 || size > 100) {
            throw new ApiException("VALIDATION_FAILED", "size must be between 1 and 100", HttpStatus.BAD_REQUEST);
        }

        PageRequest pageRequest = PageRequest.of(page, size, Sort.by(Sort.Order.desc("startedAt"), Sort.Order.desc("id")));
        Page<SessionEntity> resultPage = sessionRepository.findByUserIdOrderByStartedAtDesc(userId, pageRequest);

        List<SessionResponse> items = resultPage.getContent().stream()
                .map(s -> mapSession(s, List.of()))
                .toList();

        return new PaginatedSessionsResponse(
                items,
                resultPage.getNumber(),
                resultPage.getSize(),
                resultPage.getTotalElements(),
                resultPage.getTotalPages(),
                resultPage.hasNext()
        );
    }

    @Transactional(readOnly = true)
    public SessionResponse getSession(UUID userId, UUID sessionId) {
        SessionEntity session = sessionRepository.findByIdAndUserId(sessionId, userId)
                .orElseThrow(() -> new ApiException("NOT_FOUND", "Session not found", HttpStatus.NOT_FOUND));

        List<MessageEntity> messageEntities = messageRepository.findBySessionIdOrderBySequenceNoAsc(sessionId);
        List<MessageResponse> messages = messageEntities.stream().map(this::mapMessage).toList();
        return mapSession(session, messages);
    }

    @Transactional
    public TurnResultResponse sendMessage(UUID userId, UUID sessionId, String idempotencyKey, MessageCreateRequest req) {
        validateIdempotencyKey(idempotencyKey);
        lockUser(userId);
        String reqHash = hashString(req != null ? req.text() : "");
        idempotencyKey = hashString("POST:/sessions/" + sessionId + "/messages:" + idempotencyKey);

        Optional<IdempotencyRecord> existing = idempotencyRepository.findByUserIdAndKey(userId, idempotencyKey);
        if (existing.isPresent()) {
            IdempotencyRecord record = existing.get();
            if (!record.getRequestHash().equals(reqHash)) {
                throw new ApiException("CONFLICT", "Idempotency key reused with different request payload", HttpStatus.CONFLICT);
            }
            try {
                return objectMapper.readValue(record.getResponseBody(), TurnResultResponse.class);
            } catch (JsonProcessingException e) {
                throw new ApiException("IDEMPOTENCY_STATE_UNAVAILABLE", "Không thể khôi phục lượt hội thoại cũ.", HttpStatus.SERVICE_UNAVAILABLE);
            }
        }

        SessionEntity session = sessionRepository.findByIdAndUserId(sessionId, userId)
                .orElseThrow(() -> new ApiException("NOT_FOUND", "Session not found", HttpStatus.NOT_FOUND));

        if ("completed".equalsIgnoreCase(session.getStatus())) {
            throw new ApiException("CONFLICT", "Cannot add messages to a completed session", HttpStatus.CONFLICT);
        }

        if (req == null || req.text() == null || req.text().isBlank() || req.text().length() > 4000) {
            throw new ApiException("VALIDATION_FAILED", "Message text cannot be blank", HttpStatus.BAD_REQUEST);
        }

        long turnsToday = messageRepository.countUserTurnsSince(userId,
                Instant.now().atZone(java.time.ZoneId.of("Asia/Ho_Chi_Minh")).toLocalDate()
                        .atStartOfDay(java.time.ZoneId.of("Asia/Ho_Chi_Minh")).toInstant());
        if (turnsToday >= properties.getQuota().getMaxDailyTurns()) {
            throw new ApiException("QUOTA_EXCEEDED", "Bạn đã dùng hết lượt luyện tập hôm nay.", HttpStatus.TOO_MANY_REQUESTS);
        }
        int count = messageRepository.countBySessionId(sessionId);
        int userSeq = count + 1;
        MessageEntity userMsg = new MessageEntity(sessionId, "user", req.text().trim(), userSeq, null, null);
        userMsg = messageRepository.save(userMsg);

        Scenario scenario = null;
        if (session.getScenarioId() != null) {
            scenario = scenarioRepository.findById(session.getScenarioId()).orElse(null);
        }

        List<MessageEntity> history = messageRepository.findBySessionIdOrderBySequenceNoAsc(sessionId);
        ConversationAiService.AiTurnResult aiTurn = aiService.generateTurn(req.text(), session.getLevel(), scenario, history, learning.tutorContext(userId));

        int aiSeq = userSeq + 1;
        MessageEntity aiMsg = new MessageEntity(
                sessionId,
                "ai",
                aiTurn.text(),
                aiSeq,
                toJson(aiTurn.usefulPhrases()),
                toJson(aiTurn.suggestedFollowUps())
        );
        aiMsg = messageRepository.save(aiMsg);

        session.setDurationSeconds((int) Duration.between(session.getStartedAt(), Instant.now()).getSeconds());
        sessionRepository.save(session);

        TurnResultResponse response = new TurnResultResponse(
                mapMessage(userMsg),
                mapMessage(aiMsg),
                UUID.randomUUID().toString()
        );

        saveIdempotency(userId, idempotencyKey, "POST", "/api/v1/sessions/" + sessionId + "/messages", reqHash, 200, response);
        return response;
    }

    @Transactional
    public SessionCompleteResponse completeSession(UUID userId, UUID sessionId, String idempotencyKey) {
        validateIdempotencyKey(idempotencyKey);
        lockUser(userId);
        String reqHash = hashString("complete:" + sessionId);
        idempotencyKey = hashString("POST:/sessions/" + sessionId + "/complete:" + idempotencyKey);

        Optional<IdempotencyRecord> existing = idempotencyRepository.findByUserIdAndKey(userId, idempotencyKey);
        if (existing.isPresent()) {
            IdempotencyRecord record = existing.get();
            try {
                return objectMapper.readValue(record.getResponseBody(), SessionCompleteResponse.class);
            } catch (JsonProcessingException e) {
                throw new ApiException("IDEMPOTENCY_STATE_UNAVAILABLE", "Không thể khôi phục trạng thái kết thúc phiên.", HttpStatus.SERVICE_UNAVAILABLE);
            }
        }

        SessionEntity session = sessionRepository.findByIdAndUserId(sessionId, userId)
                .orElseThrow(() -> new ApiException("NOT_FOUND", "Session not found", HttpStatus.NOT_FOUND));

        if (!"completed".equalsIgnoreCase(session.getStatus())) {
            session.setStatus("completed");
            session.setEndedAt(Instant.now());
            session.setDurationSeconds(Math.max(1, (int) Duration.between(session.getStartedAt(), session.getEndedAt()).getSeconds()));
            sessionRepository.save(session);
        }

        // Generate feedback if absent
        if (feedbackRepository.findBySessionIdAndUserId(sessionId, userId).isEmpty()) {
            List<MessageEntity> messages = messageRepository.findBySessionIdOrderBySequenceNoAsc(sessionId);
            ConversationAiService.FeedbackData feedbackData = aiService.generateFeedback(session, messages);
            FeedbackEntity feedback = new FeedbackEntity(
                    sessionId,
                    userId,
                    feedbackData.summaryVi(),
                    toJson(feedbackData.dimensions()),
                    feedbackData.overallBand()
            );
            feedbackRepository.save(feedback);
        }

        SessionCompleteResponse response = new SessionCompleteResponse("completed", sessionId);
        saveIdempotency(userId, idempotencyKey, "POST", "/api/v1/sessions/" + sessionId + "/complete", reqHash, 202, response);
        return response;
    }

    @Transactional
    public FeedbackResponse getFeedback(UUID userId, UUID sessionId) {
        lockUser(userId);
        SessionEntity session = sessionRepository.findByIdAndUserId(sessionId, userId)
                .orElseThrow(() -> new ApiException("NOT_FOUND", "Session not found", HttpStatus.NOT_FOUND));

        if (!"completed".equals(session.getStatus())) {
            throw new ApiException("ASSESSMENT_NOT_READY", "Phiên chưa hoàn thành.", HttpStatus.CONFLICT);
        }
        FeedbackEntity feedback = feedbackRepository.findBySessionIdAndUserId(sessionId, userId)
                .orElseGet(() -> {
                    List<MessageEntity> messages = messageRepository.findBySessionIdOrderBySequenceNoAsc(sessionId);
                    ConversationAiService.FeedbackData data = aiService.generateFeedback(session, messages);
                    FeedbackEntity newFb = new FeedbackEntity(
                            sessionId,
                            userId,
                            data.summaryVi(),
                            toJson(data.dimensions()),
                            data.overallBand()
                    );
                    return feedbackRepository.save(newFb);
                });

        List<DimensionDto> dimensions = fromJson(feedback.getDimensionsJson(), new TypeReference<List<DimensionDto>>() {});
        return new FeedbackResponse(
                feedback.getId(),
                feedback.getSessionId(),
                feedback.getRubricVersion(),
                feedback.getStatus(),
                feedback.getSummaryVi(),
                dimensions != null ? dimensions : List.of(),
                null,
                List.of("Chưa có pipeline chấm điểm được kiểm chứng.", "Không có bằng chứng âm thanh để chấm phát âm."),
                List.of(), null, "not-run", "textOnly",
                messageRepository.findBySessionIdOrderBySequenceNoAsc(sessionId).stream().map(MessageEntity::getId).toList()
        );
    }

    @Transactional(readOnly = true)
    public ProgressSummaryResponse getProgressSummary(UUID userId) {
        List<SessionEntity> sessions = sessionRepository.findByUserId(userId);
        sessions = sessions.stream().filter(s -> "completed".equals(s.getStatus())).toList();
        int totalMinutes = (int) (sessions.stream().mapToLong(s -> Math.max(0, s.getDurationSeconds())).sum() / 60);
        String level = sessions.stream().max(java.util.Comparator.comparing(SessionEntity::getStartedAt))
                .map(SessionEntity::getLevel).orElse(null);
        var zone = java.time.ZoneId.of("Asia/Ho_Chi_Minh");
        Set<java.time.LocalDate> days = new HashSet<>();
        for (var session : sessions) {
            if (session.getEndedAt() != null) days.add(session.getEndedAt().atZone(zone).toLocalDate());
        }
        var day = java.time.LocalDate.now(zone);
        if (!days.contains(day)) day = day.minusDays(1);
        int streak = 0;
        while (days.contains(day)) { streak++; day = day.minusDays(1); }
        return new ProgressSummaryResponse(sessions.size(), totalMinutes, level, streak, null);
    }

    /** PostgreSQL transaction lock covers retries, quota and sequence allocation across JVMs. */
    private void lockUser(UUID userId) {
        jdbc.execute((org.springframework.jdbc.core.ConnectionCallback<Void>) connection -> {
            if ("PostgreSQL".equals(connection.getMetaData().getDatabaseProductName())) {
                try (var statement = connection.prepareStatement("select pg_advisory_xact_lock(?)")) {
                    statement.setLong(1, userId.getMostSignificantBits() ^ userId.getLeastSignificantBits());
                    statement.execute();
                }
            }
            return null;
        });
    }

    private SessionResponse mapSession(SessionEntity entity, List<MessageResponse> messages) {
        return new SessionResponse(
                entity.getId(),
                entity.getScenarioId(),
                entity.getMode(),
                entity.getStatus(),
                entity.getStartedAt(),
                entity.getEndedAt(),
                entity.getDurationSeconds(),
                messages
        );
    }

    private MessageResponse mapMessage(MessageEntity entity) {
        List<String> phrases = fromJson(entity.getUsefulPhrasesJson(), new TypeReference<List<String>>() {});
        List<String> followUps = fromJson(entity.getSuggestedFollowUpsJson(), new TypeReference<List<String>>() {});
        return new MessageResponse(
                entity.getId(),
                entity.getRole(),
                entity.getText(),
                entity.getAudioUrl(),
                entity.getSequenceNo(),
                entity.getTimestamp(),
                phrases,
                followUps
        );
    }

    private void validateIdempotencyKey(String key) {
        if (key == null || !key.matches("[A-Za-z0-9_-]{8,128}")) {
            throw new ApiException("VALIDATION_FAILED", "Header Idempotency-Key must be between 8 and 128 characters", HttpStatus.BAD_REQUEST);
        }
    }

    private void saveIdempotency(UUID userId, String key, String method, String path, String hash, int status, Object body) {
        String json = toJson(body);
        if (json == null || "[]".equals(json)) throw new IllegalStateException("Cannot serialize idempotency response");
        idempotencyRepository.saveAndFlush(new IdempotencyRecord(userId, key, method, path, hash, status, json));
    }

    private String hashString(String input) {
        if (input == null) {
            input = "";
        }
        MessageDigest md = SHA_256.get();
        md.reset();
        byte[] bytes = md.digest(input.getBytes(StandardCharsets.UTF_8));
        char[] hexChars = new char[bytes.length * 2];
        for (int i = 0; i < bytes.length; i++) {
            int v = bytes[i] & 0xFF;
            hexChars[i * 2] = Character.forDigit(v >>> 4, 16);
            hexChars[i * 2 + 1] = Character.forDigit(v & 0x0F, 16);
        }
        return new String(hexChars);
    }

    private String toJson(Object obj) {
        if (obj == null) return null;
        try {
            return objectMapper.writeValueAsString(obj);
        } catch (JsonProcessingException e) {
            return "[]";
        }
    }

    private <T> T fromJson(String json, TypeReference<T> typeRef) {
        if (json == null || json.isBlank()) return null;
        try {
            return objectMapper.readValue(json, typeRef);
        } catch (Exception e) {
            log.warn("Stored conversation JSON could not be parsed");
            return null;
        }
    }
}
