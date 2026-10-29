package com.englishspeaking.ai.ai;

import com.englishspeaking.ai.common.error.ApiException;
import com.englishspeaking.ai.config.AppProperties;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import java.net.URI;
import java.net.http.*;
import java.time.*;
import java.util.*;

/** Only short-lived, single-use, configuration-locked credentials leave the server. */
@Service
public class LiveTokenProvider {
    @org.springframework.beans.factory.annotation.Autowired(required=false)
    private com.englishspeaking.ai.provider.AiRuntimeConfig runtime;
    private final AppProperties properties;
    private final ObjectMapper mapper;
    private final HttpClient client;
    private final String endpoint;
    @org.springframework.beans.factory.annotation.Autowired
    public LiveTokenProvider(AppProperties properties, ObjectMapper mapper) {
        this(properties, mapper, HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(8))
            .followRedirects(HttpClient.Redirect.NEVER).build(),
            "https://generativelanguage.googleapis.com/v1beta/auth_tokens");
    }
    LiveTokenProvider(AppProperties properties, ObjectMapper mapper, HttpClient client, String endpoint) {
        this.properties = properties; this.mapper = mapper; this.client = client; this.endpoint = endpoint;
    }
    public boolean configured() {
        var c=snapshot();return c.configured()&&c.provider().equals("gemini")&&c.model().matches("[A-Za-z0-9._-]{1,100}");
    }
    private com.englishspeaking.ai.provider.AiRuntimeConfig.Snapshot snapshot(){var g=properties.getGemini();return runtime==null?new com.englishspeaking.ai.provider.AiRuntimeConfig.Snapshot("gemini",g.getLiveModel(),g.getApiKey()):runtime.current("live");}
    public record Ticket(String token, String model, String voice, String expiresAt, int maxSeconds,
                         Map<String, Object> setup, UUID learningSessionId, boolean saveTranscriptAllowed) {}
    public Ticket issue(String voice,String level) { return issue(voice,level,""); }
    public Ticket issue(String voice, String level, String learnerContext) {
        return issueConfigured(voice,level,learnerContext,snapshot());
    }
    public Ticket issueConfigured(String voice,String level,String learnerContext,com.englishspeaking.ai.provider.AiRuntimeConfig.Snapshot config) {
        if (!config.configured() || !config.provider().equals("gemini") || !config.model().matches("[A-Za-z0-9._-]{1,100}")) throw error("AI_NOT_CONFIGURED", "Chưa cấu hình Gemini. Hãy điền GEMINI_API_KEY trên máy chủ.", HttpStatus.SERVICE_UNAVAILABLE);
        if (!Set.of("Aoede", "Kore", "Puck", "Charon").contains(voice))
            throw error("VALIDATION_FAILED", "Giọng nói không hợp lệ.", HttpStatus.BAD_REQUEST);
        if (!Set.of("A0", "A1", "A2", "B1", "B2", "C1", "C2").contains(level))
            throw error("VALIDATION_FAILED", "Trình độ không hợp lệ.", HttpStatus.BAD_REQUEST);
        String model = "models/" + config.model();
        var setup = Map.<String, Object>of(
            "model", model,
            "generationConfig", Map.of("responseModalities", List.of("AUDIO"), "maxOutputTokens", 1024,
                "speechConfig", Map.of("voiceConfig", Map.of("prebuiltVoiceConfig", Map.of("voiceName", voice)))),
            "systemInstruction", Map.of("parts", List.of(Map.of("text",
                "You are Tom, a warm, natural English conversation partner for a Vietnamese learner at CEFR " + level + ". "
                + "Speak with a relaxed human rhythm, natural intonation and friendly expression. Keep replies to 1-3 short sentences and ask one question. "
                + "Listen patiently; allow time to think. Primarily speak English, but explain briefly in Vietnamese when asked. "
                + "Respond to what the learner actually says. Correct gently only when helpful. Never invent user speech, scores or certification. "
                + "You are an AI tutor, not a human. Do not claim to save recordings. Start with a brief greeting when asked." + learnerContext))),
            "inputAudioTranscription", Map.of(), "outputAudioTranscription", Map.of(),
            "realtimeInputConfig", Map.of("automaticActivityDetection", Map.of("disabled", false,
                "prefixPaddingMs", 300, "silenceDurationMs", 900)));
        Instant now = Instant.now();
        String expiry = now.plusSeconds(300).toString();
        try {
            // REST's schema calls this bidiGenerateContentSetup, not the SDK's liveConnectConstraints.
            // Empty fieldMask locks the entire setup; the browser cannot override it.
            var body = Map.of("uses", 1, "expireTime", expiry,
                "newSessionExpireTime", now.plusSeconds(60).toString(), "bidiGenerateContentSetup", setup);
            var request = HttpRequest.newBuilder(URI.create(endpoint)).timeout(Duration.ofSeconds(15))
                .header("Content-Type", "application/json")
                .header("x-goog-api-key", config.apiKey())
                .POST(HttpRequest.BodyPublishers.ofString(mapper.writeValueAsString(body))).build();
            var response = client.send(request,
                HttpResponse.BodyHandlers.ofByteArray());
            if (response.statusCode() == 429) throw error("AI_RATE_LIMITED", "Gemini hết hạn mức hoặc đang quá tải. Kiểm tra quota/billing rồi thử lại.", HttpStatus.TOO_MANY_REQUESTS);
            if (response.statusCode() == 400 || response.statusCode() == 401 || response.statusCode() == 403)
                throw error("AI_ACCESS_DENIED", "Key hoặc quyền truy cập Gemini Live chưa hợp lệ. Kiểm tra key, model và billing.", HttpStatus.SERVICE_UNAVAILABLE);
            if (response.statusCode() != 200) throw error("AI_UNAVAILABLE", "Gemini Live chưa khả dụng. Vui lòng thử lại sau.", HttpStatus.BAD_GATEWAY);
            String token = mapper.readTree(response.body()).path("name").asText();
            if (!token.startsWith("auth_tokens/") || token.length() > 12000) throw new IllegalStateException();
            return new Ticket(token, model, voice, expiry, 300, setup, null, false);
        } catch (ApiException e) { throw e;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw error("AI_CANCELLED", "Kết nối AI đã hủy.", HttpStatus.SERVICE_UNAVAILABLE);
        } catch (Exception e) {
            throw error("AI_UNAVAILABLE", "Không thể cấp phiên Gemini Live. Kiểm tra kết nối rồi thử lại.", HttpStatus.BAD_GATEWAY);
        }
    }
    private ApiException error(String code, String message, HttpStatus status) { return new ApiException(code, message, status); }
}
