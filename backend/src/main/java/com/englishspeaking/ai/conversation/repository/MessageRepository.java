package com.englishspeaking.ai.conversation.repository;

import com.englishspeaking.ai.conversation.domain.MessageEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface MessageRepository extends JpaRepository<MessageEntity, UUID> {
    List<MessageEntity> findBySessionIdOrderBySequenceNoAsc(UUID sessionId);
    int countBySessionId(UUID sessionId);
}
