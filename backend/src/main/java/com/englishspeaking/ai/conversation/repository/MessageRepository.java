package com.englishspeaking.ai.conversation.repository;

import com.englishspeaking.ai.conversation.domain.MessageEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface MessageRepository extends JpaRepository<MessageEntity, UUID> {
    List<MessageEntity> findBySessionIdOrderBySequenceNoAsc(UUID sessionId);
    @org.springframework.data.jpa.repository.Query("select count(m) from MessageEntity m, SessionEntity s where m.sessionId = s.id and s.userId = :userId and m.role = 'user' and m.timestamp >= :since")
    long countUserTurnsSince(@org.springframework.data.repository.query.Param("userId") UUID userId,
                            @org.springframework.data.repository.query.Param("since") java.time.Instant since);
    @org.springframework.data.jpa.repository.Query("select m from MessageEntity m, SessionEntity s where m.sessionId=s.id and s.userId=:userId and m.role='user' order by m.timestamp desc")
    List<MessageEntity> recentUserMessages(@org.springframework.data.repository.query.Param("userId") UUID userId,org.springframework.data.domain.Pageable page);
    int countBySessionId(UUID sessionId);
}
