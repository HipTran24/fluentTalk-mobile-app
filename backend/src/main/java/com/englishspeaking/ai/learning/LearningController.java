package com.englishspeaking.ai.learning;
import com.englishspeaking.ai.security.AuthenticatedUser;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.UUID;
@RestController @RequestMapping("/api/v1/me/learning")
public class LearningController {
    private final LearningService service;
    public LearningController(LearningService service){this.service=service;}
    @GetMapping public ResponseEntity<LearningService.Dashboard> get(@AuthenticationPrincipal AuthenticatedUser user){return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(service.dashboard(user.id()));}
    @PatchMapping public LearningService.Settings update(@AuthenticationPrincipal AuthenticatedUser user,@RequestBody LearningService.Settings request){return service.update(user.id(),request);}
    public record VoiceRequest(@NotNull UUID sessionId,@NotBlank @Size(max=8000) String transcript) {}
    @PostMapping("/voice-notes") public ResponseEntity<Void> save(@AuthenticationPrincipal AuthenticatedUser user,@Valid @RequestBody VoiceRequest request){service.saveVoiceNote(user.id(),request.sessionId(),request.transcript());return ResponseEntity.noContent().build();}
    @DeleteMapping("/voice-notes") public ResponseEntity<Void> clear(@AuthenticationPrincipal AuthenticatedUser user){service.clearVoiceMemory(user.id());return ResponseEntity.noContent().build();}
}
