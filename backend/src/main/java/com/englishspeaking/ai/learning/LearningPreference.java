package com.englishspeaking.ai.learning;
import jakarta.persistence.*;
import java.util.UUID;
@Entity @Table(name="learning_preferences")
public class LearningPreference {
    @Id public UUID userId;
    @Column(nullable=false) public boolean enabled;
    @Column(nullable=false) public boolean saveVoiceTranscripts;
    @Column(nullable=false,length=100) public String goal="Giao tiếp hằng ngày";
    public UUID topicId;
    @Column(nullable=false,length=20) public String voice="Aoede";
    public LearningPreference() {}
    public LearningPreference(UUID userId) { this.userId=userId; }
}
