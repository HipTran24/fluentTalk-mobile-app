package com.englishspeaking.ai.admin;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
@Entity @Table(name="admin_audit_events")
public class AdminAudit {
 @Id public UUID id=UUID.randomUUID();
 @Column(nullable=false) public UUID actorId;
 @Column(nullable=false,length=50) public String action;
 @Column(nullable=false,length=120) public String target;
 @Column(nullable=false) public Instant createdAt=Instant.now();
 public AdminAudit(){}
 public AdminAudit(UUID actor,String action,String target){this.actorId=actor;this.action=action;this.target=target;}
}
