package com.englishspeaking.ai.ai;
import com.englishspeaking.ai.common.error.ApiException;
import com.englishspeaking.ai.config.AppProperties;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.*;
import java.net.*;
import java.net.http.HttpClient;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import static org.junit.jupiter.api.Assertions.*;

class LiveTokenProviderTest {
    HttpServer server;
    final ObjectMapper mapper = new ObjectMapper();
    AppProperties properties;
    LiveTokenProvider provider;
    String requestBody;
    String response = "{\"name\":\"auth_tokens/fixture\"}";
    int status = 200, calls;
    @BeforeEach void setup() throws Exception {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/", exchange -> {
            calls++;
            requestBody = new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8);
            assertEquals("fixture-private-key", exchange.getRequestHeaders().getFirst("x-goog-api-key"));
            var bytes = response.getBytes(StandardCharsets.UTF_8);
            exchange.sendResponseHeaders(status, bytes.length); exchange.getResponseBody().write(bytes); exchange.close();
        });
        server.start(); properties = new AppProperties(); properties.getGemini().setApiKey("fixture-private-key");
        provider = new LiveTokenProvider(properties, mapper, HttpClient.newHttpClient(), "http://127.0.0.1:" + server.getAddress().getPort());
    }
    @AfterEach void close() { server.stop(0); }
    @Test void locksWholeSetupAndIssuesShortLivedSingleUseTokenWithoutKey() throws Exception {
        var ticket = provider.issue("Aoede", "A1");
        var body = mapper.readTree(requestBody);
        assertEquals(1, body.path("uses").asInt());
        assertTrue(body.has("bidiGenerateContentSetup")); assertFalse(body.has("fieldMask"));
        assertTrue(body.path("bidiGenerateContentSetup").has("systemInstruction"));
        assertEquals("Aoede", body.path("bidiGenerateContentSetup").path("generationConfig").path("speechConfig").path("voiceConfig").path("prebuiltVoiceConfig").path("voiceName").asText());
        assertTrue(Instant.parse(ticket.expiresAt()).isBefore(Instant.now().plusSeconds(301)));
        assertFalse(mapper.writeValueAsString(ticket).contains("fixture-private-key"));
        assertEquals(300, ticket.maxSeconds());
    }
    @Test void missingKeyFailsBeforeNetwork() {
        properties.getGemini().setApiKey("");
        assertEquals("AI_NOT_CONFIGURED", assertThrows(ApiException.class, () -> provider.issue("Aoede", "A1")).getCode()); assertEquals(0, calls);
    }
    @Test void invalidVoiceAndLevelFailBeforeNetwork() {
        assertThrows(ApiException.class, () -> provider.issue("invalid", "A1"));
        assertThrows(ApiException.class, () -> provider.issue("Aoede", "invalid")); assertEquals(0, calls);
    }
    @Test void upstreamErrorsAreSanitizedWithoutRetry() {
        status = 403; response = "SENSITIVE_UPSTREAM";
        var error = assertThrows(ApiException.class, () -> provider.issue("Aoede", "A1"));
        assertEquals("AI_ACCESS_DENIED", error.getCode()); assertFalse(error.getMessage().contains(response)); assertEquals(1,calls);
    }
    @Test void quotaFailureHasTypedError() {
        status = 429;
        assertEquals("AI_RATE_LIMITED", assertThrows(ApiException.class, () -> provider.issue("Aoede", "A1")).getCode());
    }
    @Test void invalidProviderCredentialIsRejected() {
        response = "{\"name\":\"not-a-token\"}";
        assertEquals("AI_UNAVAILABLE", assertThrows(ApiException.class, () -> provider.issue("Aoede", "A1")).getCode());
    }
}
