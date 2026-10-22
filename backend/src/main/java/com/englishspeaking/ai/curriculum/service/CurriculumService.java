package com.englishspeaking.ai.curriculum.service;

import com.englishspeaking.ai.common.error.ApiException;
import com.englishspeaking.ai.curriculum.dto.PaginatedScenariosDto;
import com.englishspeaking.ai.curriculum.dto.ScenarioDto;
import com.englishspeaking.ai.curriculum.dto.TopicDto;
import com.englishspeaking.ai.curriculum.dto.VocabularyItemDto;
import com.englishspeaking.ai.curriculum.model.Scenario;
import com.englishspeaking.ai.curriculum.model.Topic;
import com.englishspeaking.ai.curriculum.repository.ScenarioRepository;
import com.englishspeaking.ai.curriculum.repository.TopicRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Service
@Transactional(readOnly = true)
public class CurriculumService {

    private static final Set<String> VALID_LEVELS = Set.of("A0", "A1", "A2", "B1", "B2", "C1", "C2");

    private final TopicRepository topicRepository;
    private final ScenarioRepository scenarioRepository;
    private final ObjectMapper objectMapper;

    public CurriculumService(TopicRepository topicRepository,
                             ScenarioRepository scenarioRepository,
                             ObjectMapper objectMapper) {
        this.topicRepository = topicRepository;
        this.scenarioRepository = scenarioRepository;
        this.objectMapper = objectMapper;
    }

    public List<TopicDto> getTopics() {
        return topicRepository.findAllByOrderByCreatedAtAsc().stream()
                .map(t -> new TopicDto(t.getId(), t.getSlug(), t.getTitle()))
                .toList();
    }

    public PaginatedScenariosDto getScenarios(UUID topicId, String level, String q, int page, int size) {
        if (page < 0) {
            throw new ApiException(
                    "VALIDATION_FAILED",
                    "Query parameter 'page' must be greater than or equal to 0",
                    HttpStatus.BAD_REQUEST,
                    Map.of("parameter", "page", "value", page, "minimum", 0)
            );
        }
        if (size < 1 || size > 100) {
            throw new ApiException(
                    "VALIDATION_FAILED",
                    "Query parameter 'size' must be between 1 and 100",
                    HttpStatus.BAD_REQUEST,
                    Map.of("parameter", "size", "value", size, "minimum", 1, "maximum", 100)
            );
        }
        if (q != null) {
            int codePoints = q.codePointCount(0, q.length());
            if (codePoints > 100) {
                throw new ApiException(
                        "VALIDATION_FAILED",
                        "Query parameter 'q' must not exceed 100 characters",
                        HttpStatus.BAD_REQUEST,
                        Map.of("parameter", "q", "maxLength", 100, "actualLength", codePoints)
                );
            }
        }
        if (level != null && !VALID_LEVELS.contains(level)) {
            throw new ApiException(
                    "VALIDATION_FAILED",
                    "Query parameter 'level' must be one of " + VALID_LEVELS,
                    HttpStatus.BAD_REQUEST,
                    Map.of("parameter", "level", "value", level, "allowed", VALID_LEVELS)
            );
        }

        String kw = (q != null && !q.isBlank()) ? "%" + q.trim().toLowerCase() + "%" : null;

        // Stable deterministic pagination: Sort by createdAt ASC with id ASC tie-breaker
        Pageable pageable = PageRequest.of(
                page,
                size,
                Sort.by(Sort.Order.asc("createdAt"), Sort.Order.asc("id"))
        );
        Page<Scenario> resultPage = scenarioRepository.findFiltered(topicId, level, kw, pageable);

        List<ScenarioDto> dtos = resultPage.getContent().stream()
                .map(this::toDto)
                .toList();

        return new PaginatedScenariosDto(
                dtos,
                page,
                size,
                resultPage.hasNext()
        );
    }

    public ScenarioDto getScenarioById(UUID id) {
        Scenario scenario = scenarioRepository.findById(id)
                .filter(Scenario::isActive)
                .orElseThrow(() -> new ApiException(
                        "NOT_FOUND",
                        "Scenario with ID " + id + " was not found",
                        HttpStatus.NOT_FOUND
                ));
        return toDto(scenario);
    }

    private ScenarioDto toDto(Scenario s) {
        List<String> objectives = parseList(s.getLearningObjectives());
        List<String> phrases = parseList(s.getSamplePhrases());
        List<VocabularyItemDto> vocab = parseVocab(s.getVocabularyPreview());

        return new ScenarioDto(
                s.getId(),
                s.getTopicId(),
                s.getLevel(),
                s.getTitle(),
                s.getDescription(),
                s.getRoleAi(),
                s.getRoleUser(),
                objectives,
                s.getEstimatedMinutes(),
                phrases,
                vocab,
                s.isActive()
        );
    }

    private List<String> parseList(String json) {
        if (json == null || json.isBlank()) return Collections.emptyList();
        try {
            return objectMapper.readValue(json, new TypeReference<List<String>>() {});
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    private List<VocabularyItemDto> parseVocab(String json) {
        if (json == null || json.isBlank()) return Collections.emptyList();
        try {
            return objectMapper.readValue(json, new TypeReference<List<VocabularyItemDto>>() {});
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }
}
