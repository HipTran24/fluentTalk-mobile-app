package com.englishspeaking.ai.security;

import com.englishspeaking.ai.EnglishSpeakingAiApplication;
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
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(classes = EnglishSpeakingAiApplication.class)
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class AuthAndProfileIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwksJwtTokenVerifier tokenVerifier;

    private RSAKey testRsaKey;
    private JWSSigner signer;

    @BeforeAll
    void setupKeys() throws Exception {
        testRsaKey = new RSAKeyGenerator(2048)
                .keyID("test-kid-001")
                .generate();
        signer = new RSASSASigner(testRsaKey);
        tokenVerifier.setTestJwkSet(new JWKSet(testRsaKey.toPublicJWK()));
    }

    private String createToken(UUID userId, String email, boolean isAdmin, long ttlMillis, String audience, String issuer) throws Exception {
        Date now = new Date();
        Date exp = new Date(now.getTime() + ttlMillis);

        JWTClaimsSet.Builder builder = new JWTClaimsSet.Builder()
                .subject(userId.toString())
                .claim("email", email)
                .issueTime(now)
                .expirationTime(exp)
                .audience(audience != null ? List.of(audience) : List.of("authenticated"))
                .issuer(issuer != null ? issuer : "https://test.supabase.co/auth/v1");

        if (isAdmin) {
            builder.claim("app_metadata", Map.of("role", "admin"));
        } else {
            builder.claim("app_metadata", Map.of("role", "authenticated"));
        }

        SignedJWT signedJWT = new SignedJWT(
                new JWSHeader.Builder(JWSAlgorithm.RS256).keyID(testRsaKey.getKeyID()).build(),
                builder.build()
        );
        signedJWT.sign(signer);
        return signedJWT.serialize();
    }

    @Test
    @DisplayName("Unauthenticated request to /api/v1/me returns 401 UNAUTHENTICATED")
    void unauthenticatedMe_shouldReturn401() throws Exception {
        mockMvc.perform(get("/api/v1/me"))
                .andExpect(status().isUnauthorized())
                .andExpect(header().exists("X-Request-Id"))
                .andExpect(jsonPath("$.code", is("UNAUTHENTICATED")));
    }

    @Test
    @DisplayName("Expired JWT token returns 401 UNAUTHENTICATED")
    void expiredToken_shouldReturn401() throws Exception {
        UUID userId = UUID.randomUUID();
        String expiredToken = createToken(userId, "expired@test.com", false, -10000, "authenticated", "https://test.supabase.co/auth/v1");

        mockMvc.perform(get("/api/v1/me")
                        .header("Authorization", "Bearer " + expiredToken))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code", is("UNAUTHENTICATED")))
                .andExpect(jsonPath("$.message", is("Token has expired")));
    }

    @Test
    @DisplayName("Wrong audience token returns 401 UNAUTHENTICATED")
    void wrongAudienceToken_shouldReturn401() throws Exception {
        UUID userId = UUID.randomUUID();
        String badAudienceToken = createToken(userId, "badaud@test.com", false, 60000, "wrong-audience", "https://test.supabase.co/auth/v1");

        mockMvc.perform(get("/api/v1/me")
                        .header("Authorization", "Bearer " + badAudienceToken))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code", is("UNAUTHENTICATED")));
    }

    @Test
    @DisplayName("Valid JWT retrieves and updates own profile, ensuring two-user IDOR isolation")
    void twoUserIsolation_shouldPreventIdor() throws Exception {
        UUID userAliceId = UUID.randomUUID();
        UUID userBobId = UUID.randomUUID();

        String aliceToken = createToken(userAliceId, "alice@test.com", false, 3600000, "authenticated", "https://test.supabase.co/auth/v1");
        String bobToken = createToken(userBobId, "bob@test.com", false, 3600000, "authenticated", "https://test.supabase.co/auth/v1");

        // 1. Alice updates her profile
        mockMvc.perform(patch("/api/v1/me")
                        .header("Authorization", "Bearer " + aliceToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"displayName\":\"Alice Wonder\",\"level\":\"B1\",\"dailyMinutes\":20,\"onboarded\":true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is(userAliceId.toString())))
                .andExpect(jsonPath("$.displayName", is("Alice Wonder")))
                .andExpect(jsonPath("$.level", is("B1")))
                .andExpect(jsonPath("$.dailyMinutes", is(20)))
                .andExpect(jsonPath("$.onboarded", is(true)));

        // 2. Bob updates his profile
        mockMvc.perform(patch("/api/v1/me")
                        .header("Authorization", "Bearer " + bobToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"displayName\":\"Bob Builder\",\"level\":\"A2\",\"dailyMinutes\":10,\"onboarded\":false}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is(userBobId.toString())))
                .andExpect(jsonPath("$.displayName", is("Bob Builder")))
                .andExpect(jsonPath("$.level", is("A2")))
                .andExpect(jsonPath("$.dailyMinutes", is(10)))
                .andExpect(jsonPath("$.onboarded", is(false)));

        // 3. Verify Alice's GET /api/v1/me returns Alice's data only
        mockMvc.perform(get("/api/v1/me")
                        .header("Authorization", "Bearer " + aliceToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is(userAliceId.toString())))
                .andExpect(jsonPath("$.displayName", is("Alice Wonder")))
                .andExpect(jsonPath("$.level", is("B1")));

        // 4. Verify Bob's GET /api/v1/me returns Bob's data only
        mockMvc.perform(get("/api/v1/me")
                        .header("Authorization", "Bearer " + bobToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is(userBobId.toString())))
                .andExpect(jsonPath("$.displayName", is("Bob Builder")))
                .andExpect(jsonPath("$.level", is("A2")));
    }

    @Test
    @DisplayName("Admin denial: regular user is denied 403 on admin endpoint, admin user is allowed")
    void adminAuthorization_shouldEnforceRolePolicy() throws Exception {
        UUID regularUserId = UUID.randomUUID();
        UUID adminUserId = UUID.randomUUID();

        String regularToken = createToken(regularUserId, "regular@test.com", false, 3600000, "authenticated", "https://test.supabase.co/auth/v1");
        String adminToken = createToken(adminUserId, "admin@test.com", true, 3600000, "authenticated", "https://test.supabase.co/auth/v1");

        // Regular user denied
        mockMvc.perform(get("/api/v1/admin/status")
                        .header("Authorization", "Bearer " + regularToken))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code", is("FORBIDDEN")));

        // Admin user allowed
        mockMvc.perform(get("/api/v1/admin/status")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.admin", is("active")));
    }

    @Test
    @DisplayName("User settings default to audioRetentionDays=0 (opt-in consent required)")
    void userSettings_shouldDefaultRetentionToZero() throws Exception {
        UUID userId = UUID.randomUUID();
        String userToken = createToken(userId, "settings@test.com", false, 3600000, "authenticated", "https://test.supabase.co/auth/v1");

        mockMvc.perform(get("/api/v1/me/settings")
                        .header("Authorization", "Bearer " + userToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userId", is(userId.toString())))
                .andExpect(jsonPath("$.audioRetentionDays", is(0)))
                .andExpect(jsonPath("$.notificationsEnabled", is(true)));

        // User explicitly opts in to 14 days retention
        mockMvc.perform(patch("/api/v1/me/settings")
                        .header("Authorization", "Bearer " + userToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"audioRetentionDays\":14}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.audioRetentionDays", is(14)));
    }
}
