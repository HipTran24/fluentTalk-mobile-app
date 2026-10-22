package com.englishspeaking.ai;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(classes = EnglishSpeakingAiApplication.class)
@ActiveProfiles("test")
class ApplicationContextTest {

    @Test
    @DisplayName("Context loads when spring.classformat.ignore system property is enabled on Java 27")
    void contextLoads() {
    }
}
