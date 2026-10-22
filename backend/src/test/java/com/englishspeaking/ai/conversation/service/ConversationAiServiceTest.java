package com.englishspeaking.ai.conversation.service;

import com.englishspeaking.ai.common.error.ApiException;
import com.englishspeaking.ai.config.AppProperties;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.net.InetSocketAddress;
import java.net.http.HttpClient;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;

class ConversationAiServiceTest {
    private final ObjectMapper mapper = new ObjectMapper();
    private HttpServer server;
    private AppProperties properties;
    private ConversationAiService service;
    private String response;
    private String requestBody;
    private int status = 200;
    private final AtomicInteger requests = new AtomicInteger();

    @BeforeEach void setup() throws Exception {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/", exchange -> {
            requests.incrementAndGet();
            requestBody = new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8);
            byte[] bytes = response.getBytes(StandardCharsets.UTF_8);
            exchange.sendResponseHeaders(status, bytes.length);
            exchange.getResponseBody().write(bytes);
            exchange.close();
        });
        server.start();
        properties = new AppProperties();
        properties.getGemini().setApiKey("fixture-key");
        properties.getGemini().setModel("fixture-model");
        service = new ConversationAiService(properties, mapper, HttpClient.newHttpClient(),
                "http://127.0.0.1:" + server.getAddress().getPort() + "/");
        response = envelope("{\"text\":\"Hello!\",\"usefulPhrases\":[\"How are you?\"],\"suggestedFollowUps\":[]}", "STOP");
    }

    @AfterEach void cleanup() { server.stop(0); }

    private String envelope(String output, String reason) throws Exception {
        return mapper.writeValueAsString(Map.of("candidates", List.of(Map.of("finishReason", reason,
                "content", Map.of("parts", List.of(Map.of("text", output)))))));
    }

    @Test void acceptsStructuredOutputAndSendsCurrentTextOnlyOnce() throws Exception {
        var message = new com.englishspeaking.ai.conversation.domain.MessageEntity(
                java.util.UUID.randomUUID(), "user", "Hello", 1, null, null);
        var turn = service.generateTurn("Hello", "A1", null, List.of(message));
        assertEquals("Hello!", turn.text());
        assertEquals(1, mapper.readTree(requestBody).path("contents").size());
        assertEquals(1, requests.get());
        assertTrue(mapper.readTree(requestBody).has("systemInstruction"));
    }

    @Test void tutorNameAndScopedContextAreIncludedInInstruction() throws Exception {
        service.generateTurn("Hello", "A1", null, List.of(), "Learner context: fixture interview goal");
        String instruction=mapper.readTree(requestBody).path("systemInstruction").path("parts").path(0).path("text").asText();
        assertTrue(instruction.contains("You are Tom"));
        assertTrue(instruction.contains("fixture interview goal"));
    }

    @Test void missingConfigFailsBeforeNetwork() {
        properties.getGemini().setApiKey("");
        assertEquals("AI_NOT_CONFIGURED", assertThrows(ApiException.class,
                () -> service.generateTurn("Hello", "A1", null, List.of())).getCode());
        assertEquals(0, requests.get());
    }

    @Test void rateLimitNeverBecomesFakeSuccessOrAutomaticRetry() {
        status = 429;
        assertEquals("AI_RATE_LIMITED", assertThrows(ApiException.class,
                () -> service.generateTurn("Hello", "A1", null, List.of())).getCode());
        assertEquals(1, requests.get());
    }

    @Test void upstreamFailureIsSanitized() {
        status = 502;
        response = "PRIVATE_PROVIDER_DETAIL";
        var error = assertThrows(ApiException.class, () -> service.generateTurn("Hello", "A1", null, List.of()));
        assertEquals("AI_UNAVAILABLE", error.getCode());
        assertFalse(error.getMessage().contains(response));
    }

    @Test void rejectsTruncatedOutput() throws Exception {
        response = envelope("{}", "MAX_TOKENS");
        assertEquals("AI_INVALID_RESPONSE", assertThrows(ApiException.class,
                () -> service.generateTurn("Hello", "A1", null, List.of())).getCode());
    }

    @Test void rejectsExtraFieldsWrongTypesEmptyTextAndOversizedLists() throws Exception {
        for (String json : List.of(
                "{\"text\":\"\",\"usefulPhrases\":[],\"suggestedFollowUps\":[]}",
                "{\"text\":\"Hello\",\"usefulPhrases\":[4],\"suggestedFollowUps\":[]}",
                "{\"text\":\"Hello\",\"usefulPhrases\":[],\"suggestedFollowUps\":[],\"secret\":true}",
                "{\"text\":\"Hello\",\"usefulPhrases\":[\"a\",\"b\",\"c\",\"d\",\"e\",\"f\"],\"suggestedFollowUps\":[]}")) {
            response = envelope(json, "STOP");
            assertEquals("AI_INVALID_RESPONSE", assertThrows(ApiException.class,
                    () -> service.generateTurn("Hello", "A1", null, List.of())).getCode());
        }
    }

    @Test void textOnlyFeedbackCannotInventScoresOrAcousticEvidence() {
        var feedback = service.generateFeedback(null, List.of());
        assertNull(feedback.overallBand());
        assertEquals(4, feedback.dimensions().size());
        feedback.dimensions().forEach(d -> {
            assertNull(d.estimatedBand());
            assertNull(d.confidence());
            assertNull(d.scorerProvider());
            assertTrue(d.evidence().isEmpty());
        });
    }
}
