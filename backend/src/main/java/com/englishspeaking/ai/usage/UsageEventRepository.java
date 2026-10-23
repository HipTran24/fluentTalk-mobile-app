package com.englishspeaking.ai.usage;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;
public interface UsageEventRepository extends JpaRepository<UsageEvent,UUID> {}
