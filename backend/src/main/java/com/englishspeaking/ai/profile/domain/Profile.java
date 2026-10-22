package com.englishspeaking.ai.profile.domain;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "profiles")
public class Profile {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "email")
    private String email;

    @Column(name = "display_name", length = 100)
    private String displayName;

    @Column(name = "avatar_url")
    private String avatarUrl;

    @Column(name = "level", nullable = false, length = 20)
    private String level = "A1";

    @Column(name = "goal", length = 100)
    private String goal;

    @Column(name = "daily_minutes", nullable = false)
    private int dailyMinutes = 15;

    @Column(name = "onboarded", nullable = false)
    private boolean onboarded = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    public Profile() {}

    public Profile(UUID id, String email, String displayName) {
        this.id = id;
        this.email = email;
        this.displayName = displayName != null && !displayName.isBlank() ? displayName : "Learner";
        this.level = "A1";
        this.dailyMinutes = 15;
        this.onboarded = false;
        this.createdAt = Instant.now();
        this.updatedAt = Instant.now();
    }

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = Instant.now();
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getDisplayName() {
        return displayName != null ? displayName : "Learner";
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    public String getAvatarUrl() {
        return avatarUrl;
    }

    public void setAvatarUrl(String avatarUrl) {
        this.avatarUrl = avatarUrl;
    }

    public String getLevel() {
        return level != null ? level : "A1";
    }

    public void setLevel(String level) {
        this.level = level;
    }

    public String getGoal() {
        return goal;
    }

    public void setGoal(String goal) {
        this.goal = goal;
    }

    public int getDailyMinutes() {
        return dailyMinutes;
    }

    public void setDailyMinutes(int dailyMinutes) {
        this.dailyMinutes = dailyMinutes;
    }

    public boolean isOnboarded() {
        return onboarded;
    }

    public void setOnboarded(boolean onboarded) {
        this.onboarded = onboarded;
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
