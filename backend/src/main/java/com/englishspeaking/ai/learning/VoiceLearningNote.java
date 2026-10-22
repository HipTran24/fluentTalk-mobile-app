package com.englishspeaking.ai.learning;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
@Entity @Table(name="voice_learning_notes")
public class VoiceLearningNote {
    @Id public UUID id;
    @Column(nullable=false) public UUID userId;
    @Column(nullable=false,columnDefinition="TEXT") public String transcript;
    @Column(nullable=false) public Instant createdAt=Instant.now();
    public VoiceLearningNote() {}
}
