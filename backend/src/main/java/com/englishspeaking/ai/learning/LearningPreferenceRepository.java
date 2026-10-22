package com.englishspeaking.ai.learning;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;
public interface LearningPreferenceRepository extends JpaRepository<LearningPreference,UUID> {}
