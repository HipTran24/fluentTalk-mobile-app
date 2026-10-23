package com.englishspeaking.ai.admin;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;
public interface AdminAuditRepository extends JpaRepository<AdminAudit,UUID>{}
