package com.englishspeaking.ai.curriculum.model;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "scenarios")
public class Scenario {
    @Version @Column(nullable=false) private long revision;
    public long getRevision(){return revision;}


    @Id
    private UUID id;

    @Column(name = "topic_id", nullable = false)
    private UUID topicId;

    @Column(nullable = false, length = 20)
    private String level;

    @Column(nullable = false, length = 150)
    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String description;

    @Column(name = "role_ai", nullable = false, length = 100)
    private String roleAi;

    @Column(name = "role_user", nullable = false, length = 100)
    private String roleUser;

    @Column(name = "learning_objectives", nullable = false, columnDefinition = "TEXT")
    private String learningObjectives = "[]";

    @Column(name = "estimated_minutes", nullable = false)
    private int estimatedMinutes = 10;

    @Column(name = "sample_phrases", nullable = false, columnDefinition = "TEXT")
    private String samplePhrases = "[]";

    @Column(name = "vocabulary_preview", nullable = false, columnDefinition = "TEXT")
    private String vocabularyPreview = "[]";

    @Column(nullable = false)
    private boolean active = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    public Scenario() {}

    public Scenario(UUID id, UUID topicId, String level, String title, String description,
                    String roleAi, String roleUser, int estimatedMinutes) {
        this.id = id;
        this.topicId = topicId;
        this.level = level;
        this.title = title;
        this.description = description;
        this.roleAi = roleAi;
        this.roleUser = roleUser;
        this.estimatedMinutes = estimatedMinutes;
        this.active = true;
        this.createdAt = Instant.now();
        this.updatedAt = Instant.now();
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getTopicId() {
        return topicId;
    }

    public void setTopicId(UUID topicId) {
        this.topicId = topicId;
    }

    public String getLevel() {
        return level;
    }

    public void setLevel(String level) {
        this.level = level;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getRoleAi() {
        return roleAi;
    }

    public void setRoleAi(String roleAi) {
        this.roleAi = roleAi;
    }

    public String getRoleUser() {
        return roleUser;
    }

    public void setRoleUser(String roleUser) {
        this.roleUser = roleUser;
    }

    public String getLearningObjectives() {
        return learningObjectives;
    }

    public void setLearningObjectives(String learningObjectives) {
        this.learningObjectives = learningObjectives;
    }

    public int getEstimatedMinutes() {
        return estimatedMinutes;
    }

    public void setEstimatedMinutes(int estimatedMinutes) {
        this.estimatedMinutes = estimatedMinutes;
    }

    public String getSamplePhrases() {
        return samplePhrases;
    }

    public void setSamplePhrases(String samplePhrases) {
        this.samplePhrases = samplePhrases;
    }

    public String getVocabularyPreview() {
        return vocabularyPreview;
    }

    public void setVocabularyPreview(String vocabularyPreview) {
        this.vocabularyPreview = vocabularyPreview;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }
}
