package com.englishspeaking.ai.curriculum.repository;

import com.englishspeaking.ai.curriculum.model.Topic;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface TopicRepository extends JpaRepository<Topic, UUID> {
    List<Topic> findAllByOrderByCreatedAtAsc();
}
