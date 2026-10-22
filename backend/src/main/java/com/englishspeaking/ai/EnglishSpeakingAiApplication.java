package com.englishspeaking.ai;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class EnglishSpeakingAiApplication {

    public static void main(String[] args) {
        SpringApplication.run(EnglishSpeakingAiApplication.class, args);
    }
}
