package com.englishspeaking.ai.learning;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.*;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
@Configuration @EnableScheduling
public class VoiceNoteRetention {
    private final VoiceLearningNoteRepository notes;
    public VoiceNoteRetention(VoiceLearningNoteRepository notes){this.notes=notes;}
    @Scheduled(initialDelay=60000,fixedDelay=3600000) @Transactional
    public void purge(){notes.deleteByCreatedAtBefore(Instant.now().minus(Duration.ofDays(30)));}
}
