package com.englishspeaking.ai.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.util.ArrayList;
import java.util.List;

@Configuration
@ConfigurationProperties(prefix = "app")
public class AppProperties {

    private String version = "0.1.0";
    private final Supabase supabase = new Supabase();
    private final Gemini gemini = new Gemini();
    private final Quota quota = new Quota();
    private final Cors cors = new Cors();

    public String getVersion() {
        return version;
    }

    public void setVersion(String version) {
        this.version = version;
    }

    public Supabase getSupabase() {
        return supabase;
    }

    public Gemini getGemini() {
        return gemini;
    }

    public Quota getQuota() {
        return quota;
    }

    public Cors getCors() {
        return cors;
    }

    public static class Supabase {
        private String url = "";
        private String jwtIssuer = "";
        private String jwtAudience = "authenticated";
        private String jwksUrl = "";

        public String getUrl() {
            return url;
        }

        public void setUrl(String url) {
            this.url = url;
        }

        public String getJwtIssuer() {
            return jwtIssuer;
        }

        public void setJwtIssuer(String jwtIssuer) {
            this.jwtIssuer = jwtIssuer;
        }

        public String getJwtAudience() {
            return jwtAudience;
        }

        public void setJwtAudience(String jwtAudience) {
            this.jwtAudience = jwtAudience;
        }

        public String getJwksUrl() {
            if (jwksUrl != null && !jwksUrl.isBlank()) {
                return jwksUrl;
            }
            if (url != null && !url.isBlank()) {
                return url.replaceAll("/+$", "") + "/auth/v1/.well-known/jwks.json";
            }
            return "";
        }

        public void setJwksUrl(String jwksUrl) {
            this.jwksUrl = jwksUrl;
        }
    }

    public static class Gemini {
        private String apiKey = "";
        private String model = "";

        public String getApiKey() {
            return apiKey;
        }

        public void setApiKey(String apiKey) {
            this.apiKey = apiKey;
        }

        public String getModel() {
            return model;
        }

        public void setModel(String model) {
            this.model = model;
        }
    }

    public static class Quota {
        private int defaultDailyMinutes = 15;
        private int maxDailyTurns = 100;

        public int getDefaultDailyMinutes() {
            return defaultDailyMinutes;
        }

        public void setDefaultDailyMinutes(int defaultDailyMinutes) {
            this.defaultDailyMinutes = defaultDailyMinutes;
        }

        public int getMaxDailyTurns() {
            return maxDailyTurns;
        }

        public void setMaxDailyTurns(int maxDailyTurns) {
            this.maxDailyTurns = maxDailyTurns;
        }
    }

    public static class Cors {
        private List<String> allowedOrigins = new ArrayList<>();

        public List<String> getAllowedOrigins() {
            return allowedOrigins;
        }

        public void setAllowedOrigins(List<String> allowedOrigins) {
            this.allowedOrigins = allowedOrigins;
        }
    }
}
