package com.englishspeaking.ai.conversation.domain;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "idempotency_keys")
public class IdempotencyRecord {

    @EmbeddedId
    private IdempotencyKeyId id;

    @Column(name = "method", nullable = false, length = 16)
    private String method;

    @Column(name = "resource_path", nullable = false, length = 255)
    private String resourcePath;

    @Column(name = "request_hash", nullable = false, length = 64)
    private String requestHash;

    @Column(name = "response_status", nullable = false)
    private int responseStatus;

    @Column(name = "response_body", nullable = false, columnDefinition = "TEXT")
    private String responseBody;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    public IdempotencyRecord() {}

    public IdempotencyRecord(UUID userId, String key, String method, String resourcePath, String requestHash, int responseStatus, String responseBody) {
        this.id = new IdempotencyKeyId(userId, key);
        this.method = method;
        this.resourcePath = resourcePath;
        this.requestHash = requestHash;
        this.responseStatus = responseStatus;
        this.responseBody = responseBody;
        this.createdAt = Instant.now();
    }

    public IdempotencyKeyId getId() {
        return id;
    }

    public String getMethod() {
        return method;
    }

    public String getResourcePath() {
        return resourcePath;
    }

    public String getRequestHash() {
        return requestHash;
    }

    public int getResponseStatus() {
        return responseStatus;
    }

    public String getResponseBody() {
        return responseBody;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
