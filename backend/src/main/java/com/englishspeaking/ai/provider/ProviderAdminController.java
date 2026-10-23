package com.englishspeaking.ai.provider;

import com.englishspeaking.ai.security.AuthenticatedUser;
import com.englishspeaking.ai.ai.LiveTokenProvider;
import com.englishspeaking.ai.conversation.service.ConversationAiService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController @RequestMapping("/api/v1/admin/providers") @PreAuthorize("hasRole('ADMIN')")
public class ProviderAdminController {
    private final AiRuntimeConfig config;
    private final ConversationAiService text;
    private final LiveTokenProvider live;
    public ProviderAdminController(AiRuntimeConfig config,ConversationAiService text,LiveTokenProvider live){this.config=config;this.text=text;this.live=live;}
    @ModelAttribute public void noCache(jakarta.servlet.http.HttpServletResponse response){response.setHeader("Cache-Control","no-store");}
    @PutMapping("/{channel}") public Object save(@AuthenticationPrincipal AuthenticatedUser user,@PathVariable String channel,@Valid @RequestBody AiRuntimeConfig.Edit edit){return config.save(user.id(),channel,edit);}
    public record Reset(@NotNull @Min(-1) Long revision){}
    @PostMapping("/{channel}/reset") public Object reset(@AuthenticationPrincipal AuthenticatedUser user,@PathVariable String channel,@Valid @RequestBody Reset request){return config.reset(user.id(),channel,request.revision());}
    @PostMapping("/{channel}/check") public Object check(@PathVariable String channel,@Valid @RequestBody AiRuntimeConfig.Edit edit){
        var value=config.draft(channel,edit);
        if(channel.equals("text")) text.generateConfigured("Say hello in one short sentence.","A1",null,List.of(),"",value);
        else live.issueConfigured("Aoede","A1","",value);
        return Map.of("ok",true,"message",channel.equals("text")?"Chat trả về đúng định dạng.":"Đã cấp được phiên Live; chưa kiểm tra micro và âm thanh trình duyệt.");
    }
}
