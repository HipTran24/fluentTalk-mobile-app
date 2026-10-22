package com.englishspeaking.ai.learning;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
import java.time.Instant;
public interface VoiceLearningNoteRepository extends JpaRepository<VoiceLearningNote,UUID> {
    List<VoiceLearningNote> findTop20ByUserIdAndCreatedAtAfterOrderByCreatedAtDesc(UUID userId,Instant since);
    void deleteByUserId(UUID userId);
    void deleteByCreatedAtBefore(Instant time);
}
