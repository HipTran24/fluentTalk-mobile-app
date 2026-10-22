package com.englishspeaking.ai.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * Validates environment configuration on startup.
 * When the 'prod' profile is active, mandatory variables are strictly enforced (fail-closed).
 * In development or test profiles, missing services remain fail-closed without crashing startup.
 */
@Component
public class ProductionEnvironmentValidator implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(ProductionEnvironmentValidator.class);

    private final Environment environment;
    private final AppProperties appProperties;

    public ProductionEnvironmentValidator(Environment environment, AppProperties appProperties) {
        this.environment = environment;
        this.appProperties = appProperties;
    }

    @Override
    public void run(ApplicationArguments args) {
        List<String> activeProfiles = Arrays.asList(environment.getActiveProfiles());
        boolean isProduction = activeProfiles.contains("prod") || activeProfiles.contains("production");

        if (isProduction) {
            log.info("Running in PRODUCTION mode. Validating required environment configuration...");
            List<String> missingConfigs = new ArrayList<>();

            if (!StringUtils.hasText(appProperties.getSupabase().getUrl())) {
                missingConfigs.add("SUPABASE_URL (app.supabase.url)");
            }
            if (!StringUtils.hasText(appProperties.getSupabase().getJwtIssuer())) {
                missingConfigs.add("SUPABASE_JWT_ISSUER (app.supabase.jwt-issuer)");
            }
            if (!StringUtils.hasText(appProperties.getGemini().getApiKey())) {
                missingConfigs.add("GEMINI_API_KEY (app.gemini.api-key)");
            }
            if (!StringUtils.hasText(appProperties.getGemini().getModel())) {
                missingConfigs.add("GEMINI_MODEL (app.gemini.model)");
            }

            String datasourceUrl = environment.getProperty("spring.datasource.url");
            if (!StringUtils.hasText(datasourceUrl) || datasourceUrl.contains("h2:mem")) {
                missingConfigs.add("SPRING_DATASOURCE_URL (must point to production PostgreSQL database)");
            }

            String datasourcePassword = environment.getProperty("spring.datasource.password");
            if (!StringUtils.hasText(datasourcePassword) || "postgres".equalsIgnoreCase(datasourcePassword.trim())) {
                missingConfigs.add("SPRING_DATASOURCE_PASSWORD (production password must be configured and not default)");
            }

            if (!missingConfigs.isEmpty()) {
                String errorMsg = "CRITICAL: Production startup aborted due to missing configuration: "
                        + String.join(", ", missingConfigs)
                        + ". Fail-closed: refusing to start without verified production credentials.";
                log.error(errorMsg);
                throw new IllegalStateException(errorMsg);
            }

            log.info("Production configuration verified successfully.");
        } else {
            log.info("Running in non-production profile(s): {}. Production external integrations remain fail-closed.",
                    activeProfiles.isEmpty() ? "default" : activeProfiles);
        }
    }
}
