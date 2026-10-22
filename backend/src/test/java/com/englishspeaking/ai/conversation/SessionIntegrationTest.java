package com.englishspeaking.ai.conversation;

import com.englishspeaking.ai.EnglishSpeakingAiApplication;
import com.englishspeaking.ai.security.JwksJwtTokenVerifier;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.JWSSigner;
import com.nimbusds.jose.crypto.RSASSASigner;
import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.jwk.gen.RSAKeyGenerator;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.Date;
import java.util.List;
import java.util.UUID;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(classes = EnglishSpeakingAiApplication.class)
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class SessionIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwksJwtTokenVerifier tokenVerifier;

    private RSAKey testRsaKey;
    private JWSSigner signer;

    @BeforeAll
    void setupKeys() throws Exception {
        testRsaKey = new RSAKeyGenerator(2048)
                .keyID("test-kid-conv")
                .generate();
        signer = new RSASSASigner(testRsaKey);
        tokenVerifier.setTestJwkSet(new JWKSet(testRsaKey.toPublicJWK()));
    }

    private String createToken(UUID userId, String email) throws Exception {
        Date now = new Date();
        Date exp = new Date(now.getTime() + 3600000);
        JWTClaimsSet claims = new JWTClaimsSet.Builder()
                .subject(userId.toString())
                .issuer("https://test.supabase.co/auth/v1")
                .audience("authenticated")
                .issueTime(now)
                .expirationTime(exp)
                .claim("email", email)
                .claim("role", "authenticated")
                .build();

        SignedJWT signedJWT = new SignedJWT(
                new JWSHeader.Builder(JWSAlgorithm.RS256).keyID("test-kid-conv").build(),
                claims
        );
        signedJWT.sign(signer);
        return signedJWT.serialize();
    }

    @Test
    @DisplayName("Complete practice session lifecycle: create, turns, complete, feedback and IDOR security")
    void testSessionLifecycle() throws Exception {
        UUID userA = UUID.randomUUID();
        UUID userB = UUID.randomUUID();
        String tokenA = createToken(userA, "usera@example.com");
        String tokenB = createToken(userB, "userb@example.com");

        String sessionCreateJson = """
                {
                  "mode": "text",
                  "level": "B1"
                }
                """;

        String idemKey1 = "session-key-" + UUID.randomUUID();

        // 1. Create session as User A
        MvcResult createResult = mockMvc.perform(post("/api/v1/sessions")
                        .header("Authorization", "Bearer " + tokenA)
                        .header("Idempotency-Key", idemKey1)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(sessionCreateJson))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.mode", is("text")))
                .andExpect(jsonPath("$.status", is("active")))
                .andReturn();

        String responseBody = createResult.getResponse().getContentAsString();
        String sessionId = com.jayway.jsonpath.JsonPath.read(responseBody, "$.id");

        // 2. Replay same idempotency key -> returns cached result
        mockMvc.perform(post("/api/v1/sessions")
                        .header("Authorization", "Bearer " + tokenA)
                        .header("Idempotency-Key", idemKey1)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(sessionCreateJson))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id", is(sessionId)));

        // 3. Replay with different payload -> 409 Conflict
        mockMvc.perform(post("/api/v1/sessions")
                        .header("Authorization", "Bearer " + tokenA)
                        .header("Idempotency-Key", idemKey1)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"mode\":\"guided\",\"level\":\"C1\"}"))
                .andExpect(status().isConflict());

        // 4. Send message to session
        String msgJson = "{\"text\":\"Hello Emma, could you help me practice introducing myself?\"}";
        String turnKey1 = "turn-key-" + UUID.randomUUID();

        mockMvc.perform(post("/api/v1/sessions/" + sessionId + "/messages")
                        .header("Authorization", "Bearer " + tokenA)
                        .header("Idempotency-Key", turnKey1)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(msgJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userMessage.text", containsString("Hello Emma")))
                .andExpect(jsonPath("$.aiMessage.text").isNotEmpty())
                .andExpect(jsonPath("$.aiMessage.usefulPhrases", not(empty())))
                .andExpect(jsonPath("$.aiMessage.suggestedFollowUps", not(empty())));

        // 5. Complete session
        String completeKey = "comp-key-" + UUID.randomUUID();
        mockMvc.perform(post("/api/v1/sessions/" + sessionId + "/complete")
                        .header("Authorization", "Bearer " + tokenA)
                        .header("Idempotency-Key", completeKey))
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.status", is("completed")))
                .andExpect(jsonPath("$.sessionId", is(sessionId)));

        // 6. Get feedback
        mockMvc.perform(get("/api/v1/sessions/" + sessionId + "/feedback")
                        .header("Authorization", "Bearer " + tokenA))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.sessionId", is(sessionId)))
                .andExpect(jsonPath("$.dimensions", hasSize(4)))
                .andExpect(jsonPath("$.summaryVi").isNotEmpty());

        // 7. IDOR test: User B cannot access User A's session or feedback -> 404 Not Found
        mockMvc.perform(get("/api/v1/sessions/" + sessionId)
                        .header("Authorization", "Bearer " + tokenB))
                .andExpect(status().isNotFound());

        mockMvc.perform(get("/api/v1/sessions/" + sessionId + "/feedback")
                        .header("Authorization", "Bearer " + tokenB))
                .andExpect(status().isNotFound());

        // 8. Progress summary for User A
        mockMvc.perform(get("/api/v1/progress/summary")
                        .header("Authorization", "Bearer " + tokenA))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalSessions", greaterThanOrEqualTo(1)))
                .andExpect(jsonPath("$.currentLevel", is("B1")));
    }
}
