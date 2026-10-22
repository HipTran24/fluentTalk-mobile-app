package com.englishspeaking.ai.conversation;

import com.englishspeaking.ai.config.AppProperties;
import com.englishspeaking.ai.conversation.service.ConversationAiService;
import com.englishspeaking.ai.security.JwksJwtTokenVerifier;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nimbusds.jose.*;
import com.nimbusds.jose.crypto.RSASSASigner;
import com.nimbusds.jose.jwk.*;
import com.nimbusds.jose.jwk.gen.RSAKeyGenerator;
import com.nimbusds.jwt.*;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.*;
import java.util.concurrent.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;

/** Opt-in real PostgreSQL tests. The runner allocates a disposable schema. */
@EnabledIfEnvironmentVariable(named = "QA_POSTGRES_URL", matches = ".+")
@SpringBootTest(properties = {
        "spring.datasource.url=${QA_POSTGRES_URL}",
        "spring.datasource.username=${QA_POSTGRES_USERNAME}",
        "spring.datasource.password=${QA_POSTGRES_PASSWORD}",
        "spring.datasource.driver-class-name=org.postgresql.Driver",
        "spring.datasource.hikari.maximum-pool-size=4",
        "spring.datasource.hikari.minimum-idle=1",
        "spring.jpa.hibernate.ddl-auto=validate",
        "spring.jpa.properties.hibernate.default_schema=${QA_SCHEMA}",
        "spring.flyway.enabled=true",
        "spring.flyway.default-schema=${QA_SCHEMA}",
        "spring.flyway.schemas=${QA_SCHEMA}",
        "spring.flyway.baseline-on-migrate=false"
})
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PostgresSessionConcurrencyTest {
    @Autowired MockMvc mvc;
    @Autowired JwksJwtTokenVerifier verifier;
    @Autowired JdbcTemplate jdbc;
    @Autowired AppProperties properties;
    @Autowired ObjectMapper mapper;
    @MockitoBean ConversationAiService provider;
    RSAKey key;
    String token;
    UUID user;

    @BeforeEach void setup() throws Exception {
        user = UUID.randomUUID();
        key = new RSAKeyGenerator(2048).keyID("pg-fixture").generate();
        verifier.setTestJwkSet(new JWKSet(key.toPublicJWK()));
        var jwt = new SignedJWT(new JWSHeader.Builder(JWSAlgorithm.RS256).keyID("pg-fixture").build(),
                new JWTClaimsSet.Builder().subject(user.toString()).issuer("https://test.supabase.co/auth/v1")
                        .audience("authenticated").expirationTime(new Date(System.currentTimeMillis() + 600000)).build());
        jwt.sign(new RSASSASigner(key));
        token = jwt.serialize();
        properties.getQuota().setMaxDailyTurns(100);
        when(provider.generateTurn(anyString(), any(), any(), anyList(), anyString())).thenAnswer(invocation -> {
            Thread.sleep(100);
            return new ConversationAiService.AiTurnResult("Fixture reply", List.of(), List.of());
        });
    }

    String create(String idempotency) throws Exception {
        var response = mvc.perform(post("/api/v1/sessions").header("Authorization", "Bearer " + token)
                .header("Idempotency-Key", idempotency).contentType("application/json")
                .content("{\"mode\":\"text\",\"level\":\"B1\"}")).andReturn().getResponse();
        assertEquals(201, response.getStatus());
        return mapper.readTree(response.getContentAsString()).path("id").asText();
    }

    int turn(String session, String idempotency, String text) throws Exception {
        return mvc.perform(post("/api/v1/sessions/" + session + "/messages")
                .header("Authorization", "Bearer " + token).header("Idempotency-Key", idempotency)
                .contentType("application/json").content(mapper.writeValueAsString(Map.of("text", text))))
                .andReturn().getResponse().getStatus();
    }

    List<Integer> concurrent(Callable<Integer> first, Callable<Integer> second) throws Exception {
        var start = new CountDownLatch(1);
        try (var pool = Executors.newFixedThreadPool(2)) {
            var a = pool.submit(() -> { start.await(); return first.call(); });
            var b = pool.submit(() -> { start.await(); return second.call(); });
            start.countDown();
            return List.of(a.get(60, TimeUnit.SECONDS), b.get(60, TimeUnit.SECONDS));
        }
    }

    @Test void concurrentRetryPersistsExactlyOneTurnAndOneProviderInvocation() throws Exception {
        String session = create("create-retry-0001");
        assertEquals(List.of(200, 200), concurrent(() -> turn(session, "retry-key-0001", "Hello"),
                () -> turn(session, "retry-key-0001", "Hello")));
        assertEquals(2, jdbc.queryForObject("select count(*) from session_messages where session_id = ?", Integer.class, UUID.fromString(session)));
        verify(provider, times(1)).generateTurn(anyString(), any(), any(), anyList(), anyString());
        assertEquals(409, turn(session, "retry-key-0001", "Different payload"));
    }

    @Test void sameClientKeyOnDifferentSessionsIsScopedToResource() throws Exception {
        String first = create("create-scope-0001");
        String second = create("create-scope-0002");
        assertEquals(200, turn(first, "same-key-0001", "Hello"));
        assertEquals(200, turn(second, "same-key-0001", "Hello"));
        verify(provider, times(2)).generateTurn(anyString(), any(), any(), anyList(), anyString());
    }

    @Test void concurrentQuotaCannotOverspendLastTurn() throws Exception {
        properties.getQuota().setMaxDailyTurns(1);
        String session = create("create-quota-0001");
        var statuses = new ArrayList<>(concurrent(() -> turn(session, "quota-key-0001", "Hello"),
                () -> turn(session, "quota-key-0002", "Hi")));
        Collections.sort(statuses);
        assertEquals(List.of(200, 429), statuses);
        verify(provider, times(1)).generateTurn(anyString(), any(), any(), anyList(), anyString());
    }

    @Test void concurrentSessionCreationReusesOneSession() throws Exception {
        var ids = new CopyOnWriteArrayList<String>();
        assertEquals(List.of(201, 201), concurrent(() -> { ids.add(create("same-create-0001")); return 201; },
                () -> { ids.add(create("same-create-0001")); return 201; }));
        assertEquals(ids.get(0), ids.get(1));
        assertEquals(1, jdbc.queryForObject("select count(*) from sessions where user_id = ?", Integer.class, user));
    }
}
