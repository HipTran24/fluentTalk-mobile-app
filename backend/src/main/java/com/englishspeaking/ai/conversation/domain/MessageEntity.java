package com.englishspeaking.ai.conversation.domain;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "session_messages")
public class MessageEntity {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id = UUID.randomUUID();

    @Column(name = "session_id", nullable = false, updatable = false)
    private UUID sessionId;

    @Column(name = "role", nullable = false, length = 16)
    private String role; // "user" or "ai"

    @Column(name = "text", nullable = false, columnDefinition = "TEXT")
    private String text;

    @Column(name = "audio_url")
    private String audioUrl;

    @Column(name = "sequence_no", nullable = false)
    private int sequenceNo;

    @Column(name = "timestamp", nullable = false)
    private Instant timestamp = Instant.now();

    @Column(name = "useful_phrases", columnDefinition = "TEXT")
    private String usefulPhrasesJson;

    @Column(name = "suggested_follow_ups", columnDefinition = "TEXT")
    private String suggestedFollowUpsJson;

    public MessageEntity() {}

    public MessageEntity(UUID sessionId, String role, String text, int sequenceNo, String usefulPhrasesJson, String suggestedFollowUpsJson) {
        this.id = UUID.randomUUID();
        this.sessionId = sessionId;
        this.role = role.toLowerCase();
        this.text = text;
        this.sequenceNo = sequenceNo;
        this.timestamp = Instant.now();
        this.usefulPhrasesJson = usefulPhrasesJson;
        this.suggestedFollowUpsJson = suggestedFollowUpsJson;
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

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }

    public String getAudioUrl() {
        return audioUrl;
    }

    public void setAudioUrl(String audioUrl) {
        this.audioUrl = audioUrl;
    }

    public int getSequenceNo() {
        return sequenceNo;
    }

    public void setSequenceNo(int sequenceNo) {
        this.sequenceNo = sequenceNo;
    }

    public Instant getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(Instant timestamp) {
        this.timestamp = timestamp;
    }

    public String getUsefulPhrasesJson() {
        return usefulPhrasesJson;
    }

    public void setUsefulPhrasesJson(String usefulPhrasesJson) {
        this.usefulPhrasesJson = usefulPhrasesJson;
    }

    public String getSuggestedFollowUpsJson() {
        return suggestedFollowUpsJson;
    }

    public void setSuggestedFollowUpsJson(String suggestedFollowUpsJson) {
        this.suggestedFollowUpsJson = suggestedFollowUpsJson;
    }
}
