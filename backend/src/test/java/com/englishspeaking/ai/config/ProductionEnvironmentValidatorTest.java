package com.englishspeaking.ai.config;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.boot.DefaultApplicationArguments;
import org.springframework.mock.env.MockEnvironment;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ProductionEnvironmentValidatorTest {

    @Test
    @DisplayName("In non-production profiles, missing credentials do not throw exception")
    void nonProduction_shouldNotFailOnMissingCredentials() {
        MockEnvironment env = new MockEnvironment();
        env.setActiveProfiles("dev");

        AppProperties properties = new AppProperties();
        ProductionEnvironmentValidator validator = new ProductionEnvironmentValidator(env, properties);

        assertThatCode(() -> validator.run(new DefaultApplicationArguments()))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("In production profile, missing Supabase URL throws IllegalStateException (fail-closed)")
    void production_missingSupabaseUrl_shouldThrowException() {
        MockEnvironment env = new MockEnvironment();
        env.setActiveProfiles("prod");
        env.setProperty("spring.datasource.url", "jdbc:postgresql://db.prod.supabase.co:5432/postgres");
        env.setProperty("spring.datasource.password", "strong-prod-password");

        AppProperties properties = new AppProperties();
        properties.getSupabase().setJwtIssuer("https://project.supabase.co/auth/v1");
        properties.getGemini().setApiKey("real-gemini-key");
        properties.getGemini().setModel("gemini-2.0-flash");

        ProductionEnvironmentValidator validator = new ProductionEnvironmentValidator(env, properties);

        assertThatThrownBy(() -> validator.run(new DefaultApplicationArguments()))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("SUPABASE_URL");
    }

    @Test
    @DisplayName("In production profile, missing Gemini Model throws IllegalStateException (fail-closed)")
    void production_missingGeminiModel_shouldThrowException() {
        MockEnvironment env = new MockEnvironment();
        env.setActiveProfiles("prod");
        env.setProperty("spring.datasource.url", "jdbc:postgresql://db.prod.supabase.co:5432/postgres");
        env.setProperty("spring.datasource.password", "strong-prod-password");

        AppProperties properties = new AppProperties();
        properties.getSupabase().setUrl("https://project.supabase.co");
        properties.getSupabase().setJwtIssuer("https://project.supabase.co/auth/v1");
        properties.getGemini().setApiKey("real-gemini-key");
        properties.getGemini().setModel(""); // Missing

        ProductionEnvironmentValidator validator = new ProductionEnvironmentValidator(env, properties);

        assertThatThrownBy(() -> validator.run(new DefaultApplicationArguments()))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("GEMINI_MODEL");
    }

    @Test
    @DisplayName("In production profile, default database password throws IllegalStateException (fail-closed)")
    void production_defaultDbPassword_shouldThrowException() {
        MockEnvironment env = new MockEnvironment();
        env.setActiveProfiles("prod");
        env.setProperty("spring.datasource.url", "jdbc:postgresql://db.prod.supabase.co:5432/postgres");
        env.setProperty("spring.datasource.password", "postgres"); // Insecure default

        AppProperties properties = new AppProperties();
        properties.getSupabase().setUrl("https://project.supabase.co");
        properties.getSupabase().setJwtIssuer("https://project.supabase.co/auth/v1");
        properties.getGemini().setApiKey("real-gemini-key");
        properties.getGemini().setModel("gemini-2.0-flash");

        ProductionEnvironmentValidator validator = new ProductionEnvironmentValidator(env, properties);

        assertThatThrownBy(() -> validator.run(new DefaultApplicationArguments()))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("SPRING_DATASOURCE_PASSWORD");
    }

    @Test
    @DisplayName("In production profile with complete valid configuration, startup succeeds")
    void production_validConfiguration_shouldPass() {
        MockEnvironment env = new MockEnvironment();
        env.setActiveProfiles("prod");
        env.setProperty("spring.datasource.url", "jdbc:postgresql://db.prod.supabase.co:5432/postgres");
        env.setProperty("spring.datasource.password", "strong-secret-production-pwd");

        AppProperties properties = new AppProperties();
        properties.getSupabase().setUrl("https://project.supabase.co");
        properties.getSupabase().setJwtIssuer("https://project.supabase.co/auth/v1");
        properties.getGemini().setApiKey("valid-gemini-key");
        properties.getGemini().setModel("gemini-2.0-flash");

        ProductionEnvironmentValidator validator = new ProductionEnvironmentValidator(env, properties);

        assertThatCode(() -> validator.run(new DefaultApplicationArguments()))
                .doesNotThrowAnyException();
    }
}
