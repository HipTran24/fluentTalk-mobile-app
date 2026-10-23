package com.englishspeaking.ai.usage;
import jakarta.persistence.*;
import java.time.*;
import java.util.UUID;
@Entity @Table(name="ai_usage_events")
public class UsageEvent {
 @Id public UUID id=UUID.randomUUID();
 @Column(nullable=false) public Instant createdAt=Instant.now();
 @Column(nullable=false) public LocalDate usageDay=LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh"));
 @Column(nullable=false,length=20) public String provider;
 @Column(nullable=false,length=100) public String model;
 @Column(nullable=false,length=10) public String purpose;
 @Column(nullable=false,length=10) public String outcome;
 public Integer httpStatus;
 @Column(nullable=false) public long durationMs;
 public Long inputTokens,outputTokens,totalTokens,cachedTokens,reasoningTokens;
}
