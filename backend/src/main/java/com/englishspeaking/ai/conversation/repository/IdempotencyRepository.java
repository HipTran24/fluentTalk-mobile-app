package com.englishspeaking.ai.conversation.repository;

import com.englishspeaking.ai.conversation.domain.IdempotencyKeyId;
import com.englishspeaking.ai.conversation.domain.IdempotencyRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface IdempotencyRepository extends JpaRepository<IdempotencyRecord, IdempotencyKeyId> {
    @Query("SELECT r FROM IdempotencyRecord r WHERE r.id.userId = :userId AND r.id.key = :key")
    Optional<IdempotencyRecord> findByUserIdAndKey(@Param("userId") UUID userId, @Param("key") String key);
}
