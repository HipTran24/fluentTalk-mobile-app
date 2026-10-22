package com.englishspeaking.ai.conversation.controller;

import com.englishspeaking.ai.conversation.dto.*;
import com.englishspeaking.ai.conversation.service.SessionService;
import com.englishspeaking.ai.security.AuthenticatedUser;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
public class SessionController {

    private final SessionService sessionService;

    public SessionController(SessionService sessionService) {
        this.sessionService = sessionService;
    }

    @PostMapping("/sessions")
    public ResponseEntity<SessionResponse> createSession(
            @AuthenticationPrincipal AuthenticatedUser user,
            @RequestHeader(name = "Idempotency-Key", required = false) String idempotencyKey,
            @RequestBody(required = false) SessionCreateRequest request
    ) {
        String key = idempotencyKey != null ? idempotencyKey : UUID.randomUUID().toString();
        SessionResponse response = sessionService.createSession(user.id(), key, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/sessions")
    public ResponseEntity<PaginatedSessionsResponse> getSessions(
            @AuthenticationPrincipal AuthenticatedUser user,
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "20") int size
    ) {
        PaginatedSessionsResponse response = sessionService.getUserSessions(user.id(), page, size);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/sessions/{id}")
    public ResponseEntity<SessionResponse> getSession(
            @AuthenticationPrincipal AuthenticatedUser user,
            @PathVariable("id") UUID id
    ) {
        SessionResponse response = sessionService.getSession(user.id(), id);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/sessions/{id}/messages")
    public ResponseEntity<TurnResultResponse> sendMessage(
            @AuthenticationPrincipal AuthenticatedUser user,
            @PathVariable("id") UUID id,
            @RequestHeader(name = "Idempotency-Key", required = false) String idempotencyKey,
            @Valid @RequestBody MessageCreateRequest request
    ) {
        String key = idempotencyKey != null ? idempotencyKey : UUID.randomUUID().toString();
        TurnResultResponse response = sessionService.sendMessage(user.id(), id, key, request);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/sessions/{id}/messages")
    public ResponseEntity<List<MessageResponse>> getSessionMessages(
            @AuthenticationPrincipal AuthenticatedUser user,
            @PathVariable("id") UUID id
    ) {
        SessionResponse session = sessionService.getSession(user.id(), id);
        return ResponseEntity.ok(session.messages());
    }

    @PostMapping("/sessions/{id}/complete")
    public ResponseEntity<SessionCompleteResponse> completeSession(
            @AuthenticationPrincipal AuthenticatedUser user,
            @PathVariable("id") UUID id,
            @RequestHeader(name = "Idempotency-Key", required = false) String idempotencyKey
    ) {
        String key = idempotencyKey != null ? idempotencyKey : UUID.randomUUID().toString();
        SessionCompleteResponse response = sessionService.completeSession(user.id(), id, key);
        return ResponseEntity.status(HttpStatus.ACCEPTED).body(response);
    }

    @GetMapping("/sessions/{id}/feedback")
    public ResponseEntity<FeedbackResponse> getFeedback(
            @AuthenticationPrincipal AuthenticatedUser user,
            @PathVariable("id") UUID id
    ) {
        FeedbackResponse response = sessionService.getFeedback(user.id(), id);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/voice-sessions")
    public ResponseEntity<SessionResponse> createVoiceSession(
            @AuthenticationPrincipal AuthenticatedUser user,
            @RequestHeader(name = "Idempotency-Key", required = false) String idempotencyKey,
            @RequestBody(required = false) SessionCreateRequest request
    ) {
        SessionCreateRequest voiceReq = new SessionCreateRequest(
                request != null ? request.scenarioId() : null,
                "realtime",
                request != null ? request.level() : "B1"
        );
        String key = idempotencyKey != null ? idempotencyKey : UUID.randomUUID().toString();
        SessionResponse response = sessionService.createSession(user.id(), key, voiceReq);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/voice-sessions/{id}/complete")
    public ResponseEntity<SessionCompleteResponse> completeVoiceSession(
            @AuthenticationPrincipal AuthenticatedUser user,
            @PathVariable("id") UUID id,
            @RequestHeader(name = "Idempotency-Key", required = false) String idempotencyKey
    ) {
        String key = idempotencyKey != null ? idempotencyKey : UUID.randomUUID().toString();
        SessionCompleteResponse response = sessionService.completeSession(user.id(), id, key);
        return ResponseEntity.status(HttpStatus.ACCEPTED).body(response);
    }

    @GetMapping("/progress/summary")
    public ResponseEntity<ProgressSummaryResponse> getProgressSummary(
            @AuthenticationPrincipal AuthenticatedUser user
    ) {
        ProgressSummaryResponse response = sessionService.getProgressSummary(user.id());
        return ResponseEntity.ok(response);
    }
}
