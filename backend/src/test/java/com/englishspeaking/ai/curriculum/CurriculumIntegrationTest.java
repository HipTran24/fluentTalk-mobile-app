package com.englishspeaking.ai.curriculum;

import com.englishspeaking.ai.EnglishSpeakingAiApplication;
import com.englishspeaking.ai.curriculum.model.Scenario;
import com.englishspeaking.ai.curriculum.model.Topic;
import com.englishspeaking.ai.curriculum.repository.ScenarioRepository;
import com.englishspeaking.ai.curriculum.repository.TopicRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.UUID;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(classes = EnglishSpeakingAiApplication.class)
@AutoConfigureMockMvc
@ActiveProfiles("test")
class CurriculumIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private TopicRepository topicRepository;

    @Autowired
    private ScenarioRepository scenarioRepository;

    private UUID topic1Id;
    private UUID topic2Id;
    private UUID scenario1Id;

    @BeforeEach
    void setUp() {
        scenarioRepository.deleteAll();
        topicRepository.deleteAll();

        topic1Id = UUID.fromString("11111111-1111-1111-1111-111111111001");
        topic2Id = UUID.fromString("11111111-1111-1111-1111-111111111002");

        Topic t1 = new Topic(topic1Id, "introduction", "Làm quen & Giới thiệu");
        Topic t2 = new Topic(topic2Id, "daily_life", "Đời sống thường nhật");
        topicRepository.save(t1);
        topicRepository.save(t2);

        scenario1Id = UUID.fromString("22222222-2222-2222-2222-222222222001");
        Scenario s1 = new Scenario(
                scenario1Id,
                topic1Id,
                "A1",
                "Lần đầu gặp gỡ bạn mới",
                "Luyện tập các câu chào hỏi căn bản",
                "Bạn cùng lớp (Alex)",
                "Học viên",
                10
        );
        s1.setLearningObjectives("[\"Chào hỏi lịch sự\"]");
        s1.setSamplePhrases("[\"Hi, nice to meet you!\"]");
        s1.setVocabularyPreview("[{\"phrase\":\"nice to meet you\",\"meaningVi\":\"rất vui được gặp bạn\",\"ipa\":\"/naɪs/\"}]");
        scenarioRepository.save(s1);

        Scenario s2 = new Scenario(
                UUID.fromString("22222222-2222-2222-2222-222222222002"),
                topic2Id,
                "A2",
                "Gọi món tại quán cà phê",
                "Thực hành gọi đồ uống",
                "Barista",
                "Khách hàng",
                8
        );
        scenarioRepository.save(s2);
    }

    private void seedFullLevelsA0ThroughC2() {
        String[] levels = {"A0", "B1", "B2", "C1", "C2"};
        for (int i = 0; i < levels.length; i++) {
            String lvl = levels[i];
            UUID id = UUID.fromString(String.format("22222222-2222-2222-2222-222222222%03d", i + 10));
            Scenario s = new Scenario(
                    id,
                    topic1Id,
                    lvl,
                    "Scenario for level " + lvl,
                    "Description for level " + lvl,
                    "AI Partner",
                    "Learner",
                    10
            );
            s.setLearningObjectives("[\"Objective for " + lvl + "\"]");
            s.setSamplePhrases("[\"Sample phrase for " + lvl + "\"]");
            scenarioRepository.save(s);
        }
    }

    @Test
    @DisplayName("GET /api/v1/topics returns list of topics conforming to contract")
    void getTopics_shouldReturnTopicsList() throws Exception {
        mockMvc.perform(get("/api/v1/topics"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].slug", is("introduction")))
                .andExpect(jsonPath("$[0].title", is("Làm quen & Giới thiệu")))
                .andExpect(jsonPath("$[1].slug", is("daily_life")));
    }

    @Test
    @DisplayName("GET /api/v1/scenarios returns paginated items conforming to contract")
    void getScenarios_shouldReturnPaginatedList() throws Exception {
        mockMvc.perform(get("/api/v1/scenarios"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.page", is(0)))
                .andExpect(jsonPath("$.size", is(20)))
                .andExpect(jsonPath("$.hasMore", is(false)))
                .andExpect(jsonPath("$.items", hasSize(2)))
                .andExpect(jsonPath("$.items[0].id", is(scenario1Id.toString())))
                .andExpect(jsonPath("$.items[0].topicId", is(topic1Id.toString())))
                .andExpect(jsonPath("$.items[0].level", is("A1")))
                .andExpect(jsonPath("$.items[0].learningObjectives", hasItem("Chào hỏi lịch sự")));
    }

    @Test
    @DisplayName("GET /api/v1/scenarios with topic filter returns matching scenarios only")
    void getScenarios_filterByTopic() throws Exception {
        mockMvc.perform(get("/api/v1/scenarios")
                        .param("topic", topic2Id.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(1)))
                .andExpect(jsonPath("$.items[0].title", is("Gọi món tại quán cà phê")));
    }

    @Test
    @DisplayName("GET /api/v1/scenarios with level filter returns matching scenarios only")
    void getScenarios_filterByLevel() throws Exception {
        mockMvc.perform(get("/api/v1/scenarios")
                        .param("level", "A1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(1)))
                .andExpect(jsonPath("$.items[0].level", is("A1")));
    }

    @Test
    @DisplayName("GET /api/v1/scenarios with keyword search filters accurately")
    void getScenarios_searchByKeyword() throws Exception {
        mockMvc.perform(get("/api/v1/scenarios")
                        .param("q", "cà phê"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(1)))
                .andExpect(jsonPath("$.items[0].title", is("Gọi món tại quán cà phê")));
    }

    @Test
    @DisplayName("GET /api/v1/scenarios with valid boundary query q length 100 ASCII returns 200 OK")
    void getScenarios_validBoundaryQueryLength100_shouldReturnOk() throws Exception {
        String query100 = "a".repeat(100);
        mockMvc.perform(get("/api/v1/scenarios")
                        .param("q", query100))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items").isArray())
                .andExpect(jsonPath("$.page", is(0)))
                .andExpect(jsonPath("$.size", is(20)));
    }

    @Test
    @DisplayName("GET /api/v1/scenarios with invalid query q length 101 ASCII returns HTTP 400 structured error")
    void getScenarios_invalidQueryLength101_shouldReturn400() throws Exception {
        String query101 = "a".repeat(101);
        mockMvc.perform(get("/api/v1/scenarios")
                        .param("q", query101))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code", is("VALIDATION_FAILED")))
                .andExpect(jsonPath("$.message", containsString("100 characters")))
                .andExpect(jsonPath("$.requestId").exists())
                .andExpect(jsonPath("$.timestamp").exists());
    }

    @Test
    @DisplayName("GET /api/v1/scenarios accepts 100 Unicode code points with supplementary symbols (emojis) but rejects 101 code points")
    void getScenarios_unicodeCodePointBoundary_shouldAccept100AndReject101() throws Exception {
        String emoji = "🚀"; // U+1F680 surrogate pair (2 Java chars, 1 code point)
        String query100Emojis = emoji.repeat(100);
        String query101Emojis = emoji.repeat(101);

        // 100 emojis: length() is 200 chars, but codePointCount is 100 -> MUST BE ACCEPTED (200 OK)
        mockMvc.perform(get("/api/v1/scenarios")
                        .param("q", query100Emojis))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.page", is(0)))
                .andExpect(jsonPath("$.size", is(20)));

        // 101 emojis: codePointCount is 101 -> MUST BE REJECTED (400 Bad Request)
        mockMvc.perform(get("/api/v1/scenarios")
                        .param("q", query101Emojis))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code", is("VALIDATION_FAILED")))
                .andExpect(jsonPath("$.message", containsString("100 characters")))
                .andExpect(jsonPath("$.requestId").exists());
    }

    @Test
    @DisplayName("GET /api/v1/scenarios with invalid page -1 returns HTTP 400 structured error")
    void getScenarios_invalidPageNegative_shouldReturn400() throws Exception {
        mockMvc.perform(get("/api/v1/scenarios")
                        .param("page", "-1"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code", is("VALIDATION_FAILED")))
                .andExpect(jsonPath("$.message", containsString("page")))
                .andExpect(jsonPath("$.requestId").exists())
                .andExpect(jsonPath("$.timestamp").exists());
    }

    @Test
    @DisplayName("GET /api/v1/scenarios with invalid size 0 returns HTTP 400 structured error")
    void getScenarios_invalidSizeZero_shouldReturn400() throws Exception {
        mockMvc.perform(get("/api/v1/scenarios")
                        .param("size", "0"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code", is("VALIDATION_FAILED")))
                .andExpect(jsonPath("$.message", containsString("size")))
                .andExpect(jsonPath("$.requestId").exists())
                .andExpect(jsonPath("$.timestamp").exists());
    }

    @Test
    @DisplayName("GET /api/v1/scenarios with invalid size 101 returns HTTP 400 structured error")
    void getScenarios_invalidSizeAbove100_shouldReturn400() throws Exception {
        mockMvc.perform(get("/api/v1/scenarios")
                        .param("size", "101"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code", is("VALIDATION_FAILED")))
                .andExpect(jsonPath("$.message", containsString("size")))
                .andExpect(jsonPath("$.requestId").exists())
                .andExpect(jsonPath("$.timestamp").exists());
    }

    @ParameterizedTest
    @ValueSource(strings = {"INVALID", "Z9", "a1", "b2", "c1", "unknown"})
    @DisplayName("GET /api/v1/scenarios with invalid level enum returns HTTP 400 structured error without normalization")
    void getScenarios_invalidUnknownLevel_shouldReturn400(String invalidLevel) throws Exception {
        mockMvc.perform(get("/api/v1/scenarios")
                        .param("level", invalidLevel))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code", is("VALIDATION_FAILED")))
                .andExpect(jsonPath("$.message", containsString("level")))
                .andExpect(jsonPath("$.requestId").exists())
                .andExpect(jsonPath("$.timestamp").exists());
    }

    @ParameterizedTest
    @ValueSource(strings = {"A0", "A1", "A2", "B1", "B2", "C1", "C2"})
    @DisplayName("GET /api/v1/scenarios supports every valid CEFR level A0..C2 conforming to contract")
    void getScenarios_validA0ThroughC2Coverage_shouldFilterAccurately(String validLevel) throws Exception {
        seedFullLevelsA0ThroughC2();

        mockMvc.perform(get("/api/v1/scenarios")
                        .param("level", validLevel))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(1)))
                .andExpect(jsonPath("$.items[0].level", is(validLevel)));
    }

    @Test
    @DisplayName("GET /api/v1/scenarios preserves default page=0 and size=20 when omitted")
    void getScenarios_defaultPaginationPreserved() throws Exception {
        mockMvc.perform(get("/api/v1/scenarios"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.page", is(0)))
                .andExpect(jsonPath("$.size", is(20)));
    }

    @Test
    @DisplayName("GET /api/v1/scenarios traverses equal-createdAt rows without duplicates or omissions")
    void getScenarios_deterministicPaginationOrder() throws Exception {
        scenarioRepository.deleteAll();
        Instant sharedCreatedAt = Instant.parse("2026-01-01T00:00:00Z");
        for (int suffix = 1; suffix <= 6; suffix++) {
            UUID id = UUID.fromString(String.format(
                    "22222222-2222-2222-2222-222222222%03d", suffix));
            Scenario scenario = new Scenario(
                    id,
                    topic1Id,
                    "A1",
                    "Pagination scenario " + suffix,
                    "Deterministic pagination fixture",
                    "AI Partner",
                    "Learner",
                    10
            );
            scenario.setCreatedAt(sharedCreatedAt);
            scenario.setActive(suffix != 6);
            scenarioRepository.save(scenario);
        }

        mockMvc.perform(get("/api/v1/scenarios")
                        .param("page", "0")
                        .param("size", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(2)))
                .andExpect(jsonPath("$.hasMore", is(true)))
                .andExpect(jsonPath("$.items[0].id", is("22222222-2222-2222-2222-222222222001")))
                .andExpect(jsonPath("$.items[1].id", is("22222222-2222-2222-2222-222222222002")));

        mockMvc.perform(get("/api/v1/scenarios")
                        .param("page", "1")
                        .param("size", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(2)))
                .andExpect(jsonPath("$.hasMore", is(true)))
                .andExpect(jsonPath("$.items[0].id", is("22222222-2222-2222-2222-222222222003")))
                .andExpect(jsonPath("$.items[1].id", is("22222222-2222-2222-2222-222222222004")));

        mockMvc.perform(get("/api/v1/scenarios")
                        .param("page", "2")
                        .param("size", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(1)))
                .andExpect(jsonPath("$.hasMore", is(false)))
                .andExpect(jsonPath("$.items[0].id", is("22222222-2222-2222-2222-222222222005")));
    }

    @Test
    @DisplayName("GET /api/v1/scenarios/{id} returns single scenario detail")
    void getScenarioDetail_success() throws Exception {
        mockMvc.perform(get("/api/v1/scenarios/" + scenario1Id))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is(scenario1Id.toString())))
                .andExpect(jsonPath("$.roleAi", is("Bạn cùng lớp (Alex)")))
                .andExpect(jsonPath("$.vocabularyPreview[0].phrase", is("nice to meet you")));
    }

    @Test
    @DisplayName("GET /api/v1/scenarios/{id} with unknown ID returns 404 standard error")
    void getScenarioDetail_notFound() throws Exception {
        UUID unknownId = UUID.randomUUID();
        mockMvc.perform(get("/api/v1/scenarios/" + unknownId))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code", is("NOT_FOUND")))
                .andExpect(jsonPath("$.timestamp").exists())
                .andExpect(jsonPath("$.requestId").exists());
    }
}
