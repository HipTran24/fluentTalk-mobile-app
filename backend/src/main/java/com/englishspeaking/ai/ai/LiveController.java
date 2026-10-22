package com.englishspeaking.ai.ai;
import com.englishspeaking.ai.config.AppProperties;
import com.englishspeaking.ai.security.AuthenticatedUser;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/ai")
public class LiveController {
    private final LiveTokenProvider provider;
    private final LiveAccessService access;
    private final AppProperties properties;
    public LiveController(LiveTokenProvider provider, LiveAccessService access, AppProperties properties) {
        this.provider=provider; this.access=access; this.properties=properties;
    }
    public record LiveRequest(String voice, String level) {}
    @GetMapping("/status")
    public Map<String, Object> status() {
        var g = properties.getGemini();
        return Map.of("textConfigured", !g.getApiKey().isBlank() && !g.getModel().isBlank(),
            "liveConfigured", provider.configured());
    }
    @PostMapping("/live-token")
    public ResponseEntity<LiveTokenProvider.Ticket> token(@AuthenticationPrincipal AuthenticatedUser user,
                                                        @RequestBody(required=false) LiveRequest request) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).header("Pragma", "no-cache")
            .body(access.issue(user.id(), request != null && request.voice()!=null ? request.voice() : "Aoede",
                request != null && request.level()!=null ? request.level() : "A1"));
    }
}
