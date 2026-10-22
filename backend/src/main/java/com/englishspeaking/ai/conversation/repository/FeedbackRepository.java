package com.englishspeaking.ai.conversation.repository;

import com.englishspeaking.ai.conversation.domain.FeedbackEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface FeedbackRepository extends JpaRepository<FeedbackEntity, UUID> {
    Optional<FeedbackEntity> findBySessionIdAndUserId(UUID sessionId, UUID userId);
    Optional<FeedbackEntity> findBySessionId(UUID sessionId);
}
