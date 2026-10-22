package com.englishspeaking.ai.curriculum.controller;

import com.englishspeaking.ai.common.error.ApiException;
import com.englishspeaking.ai.curriculum.dto.PaginatedScenariosDto;
import com.englishspeaking.ai.curriculum.dto.ScenarioDto;
import com.englishspeaking.ai.curriculum.dto.TopicDto;
import com.englishspeaking.ai.curriculum.service.CurriculumService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
public class CurriculumController {

    private static final Set<String> VALID_LEVELS = Set.of("A0", "A1", "A2", "B1", "B2", "C1", "C2");

    private final CurriculumService curriculumService;

    public CurriculumController(CurriculumService curriculumService) {
        this.curriculumService = curriculumService;
    }

    @GetMapping("/topics")
    public ResponseEntity<List<TopicDto>> getTopics() {
        List<TopicDto> topics = curriculumService.getTopics();
        return ResponseEntity.ok(topics);
    }

    @GetMapping("/scenarios")
    public ResponseEntity<PaginatedScenariosDto> getScenarios(
            @RequestParam(name = "topic", required = false) UUID topic,
            @RequestParam(name = "level", required = false) String level,
            @RequestParam(name = "q", required = false) String q,
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "20") int size
    ) {
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

        PaginatedScenariosDto result = curriculumService.getScenarios(topic, level, q, page, size);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/scenarios/{id}")
    public ResponseEntity<ScenarioDto> getScenarioDetail(@PathVariable("id") UUID id) {
        ScenarioDto scenario = curriculumService.getScenarioById(id);
        return ResponseEntity.ok(scenario);
    }
}
