package com.englishspeaking.ai.conversation.domain;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "session_feedbacks")
public class FeedbackEntity {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id = UUID.randomUUID();

    @Column(name = "session_id", nullable = false, updatable = false, unique = true)
    private UUID sessionId;

    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    @Column(name = "rubric_version", nullable = false, length = 32)
    private String rubricVersion = "v1.1";

    @Column(name = "status", nullable = false, length = 32)
    private String status = "ready";

    @Column(name = "summary_vi", nullable = false, columnDefinition = "TEXT")
    private String summaryVi;

    @Column(name = "dimensions", nullable = false, columnDefinition = "TEXT")
    private String dimensionsJson;

    @Column(name = "overall_band")
    private Double overallBand;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    public FeedbackEntity() {}

    public FeedbackEntity(UUID sessionId, UUID userId, String summaryVi, String dimensionsJson, Double overallBand) {
        this.id = UUID.randomUUID();
        this.sessionId = sessionId;
        this.userId = userId;
        this.rubricVersion = "v1.1";
        this.status = "ready";
        this.summaryVi = summaryVi;
        this.dimensionsJson = dimensionsJson;
        this.overallBand = overallBand;
        this.createdAt = Instant.now();
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getSessionId() {
        return sessionId;
    }

    public void setSessionId(UUID sessionId) {
        this.sessionId = sessionId;
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public String getRubricVersion() {
        return rubricVersion;
    }

    public void setRubricVersion(String rubricVersion) {
        this.rubricVersion = rubricVersion;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getSummaryVi() {
        return summaryVi;
    }

    public void setSummaryVi(String summaryVi) {
        this.summaryVi = summaryVi;
    }

    public String getDimensionsJson() {
        return dimensionsJson;
    }

    public void setDimensionsJson(String dimensionsJson) {
        this.dimensionsJson = dimensionsJson;
    }

    public Double getOverallBand() {
        return overallBand;
    }

    public void setOverallBand(Double overallBand) {
        this.overallBand = overallBand;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
