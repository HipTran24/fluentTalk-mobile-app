package com.englishspeaking.ai.conversation.service;

import com.englishspeaking.ai.common.error.ApiException;
import com.englishspeaking.ai.conversation.domain.FeedbackEntity;
import com.englishspeaking.ai.conversation.domain.IdempotencyRecord;
import com.englishspeaking.ai.conversation.domain.MessageEntity;
import com.englishspeaking.ai.conversation.domain.SessionEntity;
import com.englishspeaking.ai.conversation.dto.*;
import com.englishspeaking.ai.conversation.repository.FeedbackRepository;
import com.englishspeaking.ai.conversation.repository.IdempotencyRepository;
import com.englishspeaking.ai.conversation.repository.MessageRepository;
import com.englishspeaking.ai.conversation.repository.SessionRepository;
import com.englishspeaking.ai.curriculum.model.Scenario;
import com.englishspeaking.ai.curriculum.repository.ScenarioRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.time.Instant;
import java.util.*;

@Service
public class SessionService {

    private static final Logger log = LoggerFactory.getLogger(SessionService.class);
    private static final Set<String> VALID_MODES = Set.of("text", "guided", "realtime");
    private static final ThreadLocal<MessageDigest> SHA_256 = ThreadLocal.withInitial(() -> {
        try {
            return MessageDigest.getInstance("SHA-256");
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 algorithm not available", e);
        }
    });

    private final SessionRepository sessionRepository;
    private final MessageRepository messageRepository;
    private final FeedbackRepository feedbackRepository;
    private final IdempotencyRepository idempotencyRepository;
    private final ScenarioRepository scenarioRepository;
    private final ConversationAiService aiService;
    private final ObjectMapper objectMapper;

    public SessionService(
            SessionRepository sessionRepository,
            MessageRepository messageRepository,
            FeedbackRepository feedbackRepository,
            IdempotencyRepository idempotencyRepository,
            ScenarioRepository scenarioRepository,
            ConversationAiService aiService,
            ObjectMapper objectMapper
    ) {
        this.sessionRepository = sessionRepository;
        this.messageRepository = messageRepository;
        this.feedbackRepository = feedbackRepository;
        this.idempotencyRepository = idempotencyRepository;
        this.scenarioRepository = scenarioRepository;
        this.aiService = aiService;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public SessionResponse createSession(UUID userId, String idempotencyKey, SessionCreateRequest req) {
        validateIdempotencyKey(idempotencyKey);
        String reqHash = hashString(req != null ? req.toString() : "");

        Optional<IdempotencyRecord> existing = idempotencyRepository.findByUserIdAndKey(userId, idempotencyKey);
        if (existing.isPresent()) {
            IdempotencyRecord record = existing.get();
            if (!record.getRequestHash().equals(reqHash)) {
                throw new ApiException("CONFLICT", "Idempotency key reused with different request payload", HttpStatus.CONFLICT);
            }
            try {
                return objectMapper.readValue(record.getResponseBody(), SessionResponse.class);
            } catch (JsonProcessingException e) {
                log.warn("Failed to deserialize cached idempotency response: {}", e.getMessage());
            }
        }

        if (req == null || req.mode() == null || !VALID_MODES.contains(req.mode().toLowerCase())) {
            throw new ApiException("VALIDATION_FAILED", "Mode must be one of: text, guided, realtime", HttpStatus.BAD_REQUEST);
        }

        Scenario scenario = null;
        if (req.scenarioId() != null) {
            scenario = scenarioRepository.findById(req.scenarioId())
                    .orElseThrow(() -> new ApiException("NOT_FOUND", "Scenario not found", HttpStatus.NOT_FOUND));
        }

        SessionEntity session = new SessionEntity(userId, req.scenarioId(), req.mode(), req.level());
        session = sessionRepository.save(session);

        List<MessageResponse> messages = new ArrayList<>();
        // If guided/text scenario has a starter prompt from AI, seed the initial message
        if (scenario != null && scenario.getRoleAi() != null) {
            String initialText = String.format("Hello! I am your %s for today's scenario \"%s\". How would you like to start?",
                    scenario.getRoleAi(), scenario.getTitle());
            String samplePhrasesJson = scenario.getSamplePhrases() != null && !scenario.getSamplePhrases().isBlank()
                    ? scenario.getSamplePhrases()
                    : "[\"Let's begin!\"]";
            MessageEntity firstAiMsg = new MessageEntity(
                    session.getId(),
                    "ai",
                    initialText,
                    1,
                    samplePhrasesJson,
                    toJson(List.of("I am ready to begin.", "Could you explain our scenario goals?"))
            );
            firstAiMsg = messageRepository.save(firstAiMsg);
            messages.add(mapMessage(firstAiMsg));
        }

        SessionResponse response = mapSession(session, messages);
        saveIdempotency(userId, idempotencyKey, "POST", "/api/v1/sessions", reqHash, 201, response);
        return response;
    }

    @Transactional(readOnly = true)
    public PaginatedSessionsResponse getUserSessions(UUID userId, int page, int size) {
        if (page < 0) {
            throw new ApiException("VALIDATION_FAILED", "page must be >= 0", HttpStatus.BAD_REQUEST);
        }
        if (size < 1 || size > 100) {
            throw new ApiException("VALIDATION_FAILED", "size must be between 1 and 100", HttpStatus.BAD_REQUEST);
        }

        PageRequest pageRequest = PageRequest.of(page, size, Sort.by(Sort.Order.desc("startedAt"), Sort.Order.desc("id")));
        Page<SessionEntity> resultPage = sessionRepository.findByUserIdOrderByStartedAtDesc(userId, pageRequest);

        List<SessionResponse> items = resultPage.getContent().stream()
                .map(s -> mapSession(s, List.of()))
                .toList();

        return new PaginatedSessionsResponse(
                items,
                resultPage.getNumber(),
                resultPage.getSize(),
                resultPage.getTotalElements(),
                resultPage.getTotalPages(),
                resultPage.hasNext()
        );
    }

    @Transactional(readOnly = true)
    public SessionResponse getSession(UUID userId, UUID sessionId) {
        SessionEntity session = sessionRepository.findByIdAndUserId(sessionId, userId)
                .orElseThrow(() -> new ApiException("NOT_FOUND", "Session not found", HttpStatus.NOT_FOUND));

        List<MessageEntity> messageEntities = messageRepository.findBySessionIdOrderBySequenceNoAsc(sessionId);
        List<MessageResponse> messages = messageEntities.stream().map(this::mapMessage).toList();
        return mapSession(session, messages);
    }

    @Transactional
    public TurnResultResponse sendMessage(UUID userId, UUID sessionId, String idempotencyKey, MessageCreateRequest req) {
        validateIdempotencyKey(idempotencyKey);
        String reqHash = hashString(req != null ? req.text() : "");

        Optional<IdempotencyRecord> existing = idempotencyRepository.findByUserIdAndKey(userId, idempotencyKey);
        if (existing.isPresent()) {
            IdempotencyRecord record = existing.get();
            if (!record.getRequestHash().equals(reqHash)) {
                throw new ApiException("CONFLICT", "Idempotency key reused with different request payload", HttpStatus.CONFLICT);
            }
            try {
                return objectMapper.readValue(record.getResponseBody(), TurnResultResponse.class);
            } catch (JsonProcessingException e) {
                log.warn("Failed to deserialize cached turn response: {}", e.getMessage());
            }
        }

        SessionEntity session = sessionRepository.findByIdAndUserId(sessionId, userId)
                .orElseThrow(() -> new ApiException("NOT_FOUND", "Session not found", HttpStatus.NOT_FOUND));

        if ("completed".equalsIgnoreCase(session.getStatus())) {
            throw new ApiException("CONFLICT", "Cannot add messages to a completed session", HttpStatus.CONFLICT);
        }

        if (req == null || req.text() == null || req.text().isBlank()) {
            throw new ApiException("VALIDATION_FAILED", "Message text cannot be blank", HttpStatus.BAD_REQUEST);
        }

        int count = messageRepository.countBySessionId(sessionId);
        int userSeq = count + 1;
        MessageEntity userMsg = new MessageEntity(sessionId, "user", req.text().trim(), userSeq, null, null);
        userMsg = messageRepository.save(userMsg);

        Scenario scenario = null;
        if (session.getScenarioId() != null) {
            scenario = scenarioRepository.findById(session.getScenarioId()).orElse(null);
        }

        List<MessageEntity> history = messageRepository.findBySessionIdOrderBySequenceNoAsc(sessionId);
        ConversationAiService.AiTurnResult aiTurn = aiService.generateTurn(req.text(), session.getLevel(), scenario, history);

        int aiSeq = userSeq + 1;
        MessageEntity aiMsg = new MessageEntity(
                sessionId,
                "ai",
                aiTurn.text(),
                aiSeq,
                toJson(aiTurn.usefulPhrases()),
                toJson(aiTurn.suggestedFollowUps())
        );
        aiMsg = messageRepository.save(aiMsg);

        session.setDurationSeconds((int) Duration.between(session.getStartedAt(), Instant.now()).getSeconds());
        sessionRepository.save(session);

        TurnResultResponse response = new TurnResultResponse(
                mapMessage(userMsg),
                mapMessage(aiMsg),
                UUID.randomUUID().toString()
        );

        saveIdempotency(userId, idempotencyKey, "POST", "/api/v1/sessions/" + sessionId + "/messages", reqHash, 200, response);
        return response;
    }

    @Transactional
    public SessionCompleteResponse completeSession(UUID userId, UUID sessionId, String idempotencyKey) {
        validateIdempotencyKey(idempotencyKey);
        String reqHash = hashString("complete:" + sessionId);

        Optional<IdempotencyRecord> existing = idempotencyRepository.findByUserIdAndKey(userId, idempotencyKey);
        if (existing.isPresent()) {
            IdempotencyRecord record = existing.get();
            try {
                return objectMapper.readValue(record.getResponseBody(), SessionCompleteResponse.class);
            } catch (JsonProcessingException e) {
                log.warn("Failed to deserialize cached complete response: {}", e.getMessage());
            }
        }

        SessionEntity session = sessionRepository.findByIdAndUserId(sessionId, userId)
                .orElseThrow(() -> new ApiException("NOT_FOUND", "Session not found", HttpStatus.NOT_FOUND));

        if (!"completed".equalsIgnoreCase(session.getStatus())) {
            session.setStatus("completed");
            session.setEndedAt(Instant.now());
            session.setDurationSeconds(Math.max(1, (int) Duration.between(session.getStartedAt(), session.getEndedAt()).getSeconds()));
            sessionRepository.save(session);
        }

        // Generate feedback if absent
        if (feedbackRepository.findBySessionIdAndUserId(sessionId, userId).isEmpty()) {
            List<MessageEntity> messages = messageRepository.findBySessionIdOrderBySequenceNoAsc(sessionId);
            ConversationAiService.FeedbackData feedbackData = aiService.generateFeedback(session, messages);
            FeedbackEntity feedback = new FeedbackEntity(
                    sessionId,
                    userId,
                    feedbackData.summaryVi(),
                    toJson(feedbackData.dimensions()),
                    feedbackData.overallBand()
            );
            feedbackRepository.save(feedback);
        }

        SessionCompleteResponse response = new SessionCompleteResponse("completed", sessionId);
        saveIdempotency(userId, idempotencyKey, "POST", "/api/v1/sessions/" + sessionId + "/complete", reqHash, 202, response);
        return response;
    }

    @Transactional
    public FeedbackResponse getFeedback(UUID userId, UUID sessionId) {
        SessionEntity session = sessionRepository.findByIdAndUserId(sessionId, userId)
                .orElseThrow(() -> new ApiException("NOT_FOUND", "Session not found", HttpStatus.NOT_FOUND));

        FeedbackEntity feedback = feedbackRepository.findBySessionIdAndUserId(sessionId, userId)
                .orElseGet(() -> {
                    List<MessageEntity> messages = messageRepository.findBySessionIdOrderBySequenceNoAsc(sessionId);
                    ConversationAiService.FeedbackData data = aiService.generateFeedback(session, messages);
                    FeedbackEntity newFb = new FeedbackEntity(
                            sessionId,
                            userId,
                            data.summaryVi(),
                            toJson(data.dimensions()),
                            data.overallBand()
                    );
                    return feedbackRepository.save(newFb);
                });

        List<DimensionDto> dimensions = fromJson(feedback.getDimensionsJson(), new TypeReference<List<DimensionDto>>() {});
        return new FeedbackResponse(
                feedback.getId(),
                feedback.getSessionId(),
                feedback.getRubricVersion(),
                feedback.getStatus(),
                feedback.getSummaryVi(),
                dimensions != null ? dimensions : List.of()
        );
    }

    @Transactional(readOnly = true)
    public ProgressSummaryResponse getProgressSummary(UUID userId) {
        List<SessionEntity> sessions = sessionRepository.findByUserId(userId);
        int totalSessions = sessions.size();
        int totalMinutes = sessions.stream().mapToInt(s -> Math.max(1, s.getDurationSeconds() / 60)).sum();

        double avgBand = 6.0;
        String level = "B1";
        if (!sessions.isEmpty()) {
            SessionEntity latest = sessions.get(sessions.size() - 1);
            if (latest.getLevel() != null) {
                level = latest.getLevel();
            }
        }

        return new ProgressSummaryResponse(
                totalSessions,
                Math.max(15, totalMinutes),
                level,
                Math.max(1, Math.min(7, totalSessions)),
                avgBand
        );
    }

    private SessionResponse mapSession(SessionEntity entity, List<MessageResponse> messages) {
        return new SessionResponse(
                entity.getId(),
                entity.getScenarioId(),
                entity.getMode(),
                entity.getStatus(),
                entity.getStartedAt(),
                entity.getEndedAt(),
                entity.getDurationSeconds(),
                messages
        );
    }

    private MessageResponse mapMessage(MessageEntity entity) {
        List<String> phrases = fromJson(entity.getUsefulPhrasesJson(), new TypeReference<List<String>>() {});
        List<String> followUps = fromJson(entity.getSuggestedFollowUpsJson(), new TypeReference<List<String>>() {});
        return new MessageResponse(
                entity.getId(),
                entity.getRole(),
                entity.getText(),
                entity.getAudioUrl(),
                entity.getSequenceNo(),
                entity.getTimestamp(),
                phrases,
                followUps
        );
    }

    private void validateIdempotencyKey(String key) {
        if (key == null || key.length() < 8 || key.length() > 128) {
            throw new ApiException("VALIDATION_FAILED", "Header Idempotency-Key must be between 8 and 128 characters", HttpStatus.BAD_REQUEST);
        }
    }

    private void saveIdempotency(UUID userId, String key, String method, String path, String hash, int status, Object body) {
        try {
            String json = objectMapper.writeValueAsString(body);
            IdempotencyRecord record = new IdempotencyRecord(userId, key, method, path, hash, status, json);
            idempotencyRepository.save(record);
        } catch (Exception e) {
            log.warn("Failed to persist idempotency key [{}]: {}", key, e.getMessage());
        }
    }

    private String hashString(String input) {
        if (input == null) {
            input = "";
        }
        MessageDigest md = SHA_256.get();
        md.reset();
        byte[] bytes = md.digest(input.getBytes(StandardCharsets.UTF_8));
        char[] hexChars = new char[bytes.length * 2];
        for (int i = 0; i < bytes.length; i++) {
            int v = bytes[i] & 0xFF;
            hexChars[i * 2] = Character.forDigit(v >>> 4, 16);
            hexChars[i * 2 + 1] = Character.forDigit(v & 0x0F, 16);
        }
        return new String(hexChars);
    }

    private String toJson(Object obj) {
        if (obj == null) return null;
        try {
            return objectMapper.writeValueAsString(obj);
        } catch (JsonProcessingException e) {
            return "[]";
        }
    }

    private <T> T fromJson(String json, TypeReference<T> typeRef) {
        if (json == null || json.isBlank()) return null;
        try {
            return objectMapper.readValue(json, typeRef);
        } catch (Exception e) {
            log.warn("Failed to parse JSON: '{}' with error: {}", json, e.getMessage());
            return null;
        }
    }
}
