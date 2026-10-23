package com.englishspeaking.ai.admin.controller;
import com.englishspeaking.ai.admin.*;
import com.englishspeaking.ai.security.AuthenticatedUser;
import com.englishspeaking.ai.curriculum.repository.TopicRepository;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;
import java.util.*;
@RestController @RequestMapping("/api/v1/admin") @PreAuthorize("hasRole('ADMIN')")
public class AdminController {
 @org.springframework.beans.factory.annotation.Autowired private com.englishspeaking.ai.usage.UsageAnalytics usage;
 @GetMapping("/usage") public Object usage(@RequestParam(defaultValue="7") int days,@RequestParam(defaultValue="") String provider){return usage.read(days,provider);}
 private final AdminService service;private final TopicRepository topics;
 public AdminController(AdminService s,TopicRepository t){service=s;topics=t;}
 @ModelAttribute public void noCache(jakarta.servlet.http.HttpServletResponse response){response.setHeader("Cache-Control","no-store");}
 @GetMapping("/status") public Map<String,String> status(){return Map.of("admin","active","access","granted");}
 @GetMapping("/summary") public Object summary(){return service.summary();}
 @GetMapping("/learners") public Object learners(@RequestParam(defaultValue="") String q,@RequestParam(defaultValue="") String level,@RequestParam(defaultValue="0") int page,@RequestParam(defaultValue="20") int size){return service.learners(q,level,page,size);}
 @PatchMapping("/learners/{id}") public Object learner(@AuthenticationPrincipal AuthenticatedUser user,@PathVariable UUID id,@Valid @RequestBody AdminService.LearnerEdit request){return service.updateLearner(user.id(),id,request);}
 @GetMapping("/scenarios") public Object scenarios(@RequestParam(defaultValue="") String q,@RequestParam(required=false) UUID topic,@RequestParam(required=false) Boolean active,@RequestParam(defaultValue="0") int page,@RequestParam(defaultValue="20") int size){return service.scenarios(q,topic,active,page,size);}
 @PutMapping("/scenarios/{id}") public Object scenario(@AuthenticationPrincipal AuthenticatedUser user,@PathVariable UUID id,@Valid @RequestBody AdminService.ScenarioEdit request){return service.saveScenario(user.id(),id,request);}
 @GetMapping("/topics") public Object topics(){return topics.findAllByOrderByCreatedAtAsc();}
 @PutMapping("/topics/{id}") public Object topic(@AuthenticationPrincipal AuthenticatedUser user,@PathVariable UUID id,@Valid @RequestBody AdminService.TopicEdit request){return service.saveTopic(user.id(),id,request);}
 @GetMapping("/audit") public Object audit(@RequestParam(defaultValue="0") int page,@RequestParam(defaultValue="20") int size){return service.audit(page,size);}
 @GetMapping("/services") public Object services(){return service.services();}
}
