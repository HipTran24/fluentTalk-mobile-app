package com.englishspeaking.ai.admin;
import com.englishspeaking.ai.EnglishSpeakingAiApplication;
import com.englishspeaking.ai.security.*;
import com.englishspeaking.ai.profile.domain.Profile;
import com.englishspeaking.ai.profile.infrastructure.ProfileRepository;
import com.englishspeaking.ai.curriculum.model.Topic;
import com.englishspeaking.ai.curriculum.repository.TopicRepository;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.http.MediaType;
import java.util.*;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(classes=EnglishSpeakingAiApplication.class) @AutoConfigureMockMvc @ActiveProfiles("test")
class AdminIntegrationTest {
 @Autowired MockMvc mvc;@Autowired ProfileRepository profiles;@Autowired TopicRepository topics;@Autowired AdminAuditRepository audit;
 @MockitoBean JwksJwtTokenVerifier verifier;
 UUID admin,user,topic;
 @BeforeEach void setup(){
  admin=UUID.randomUUID();user=UUID.randomUUID();topic=UUID.randomUUID();
  when(verifier.verify("admin-fixture")).thenReturn(new AuthenticatedUser(admin,"admin@example.test",List.of("USER","ADMIN")));
  when(verifier.verify("learner-fixture")).thenReturn(new AuthenticatedUser(user,"learner@example.test",List.of("USER")));
  profiles.save(new Profile(admin,"admin@example.test","Admin"));profiles.save(new Profile(user,"learner@example.test","Learner"));
  topics.save(new Topic(topic,"topic-"+topic,"Fixture topic"));
 }
 @Test void everyReadEndpointRejectsAnonymousAndLearners()throws Exception{
  for(String path:List.of("status","summary","learners","scenarios","topics","audit","services","usage")){
   mvc.perform(get("/api/v1/admin/"+path)).andExpect(status().isUnauthorized());
   mvc.perform(get("/api/v1/admin/"+path).header("Authorization","Bearer learner-fixture")).andExpect(status().isForbidden());
  }
 }
 @Test void adminCannotUseLearnerApisEvenWithBothRoles()throws Exception{
  // Fixture deliberately includes USER + ADMIN to prevent inherited-role bypass.
  for(String path:List.of("/sessions","/progress/summary","/me/settings","/topics","/scenarios")){
   mvc.perform(get("/api/v1"+path).header("Authorization","Bearer admin-fixture")).andExpect(status().isForbidden());
  }
  mvc.perform(post("/api/v1/sessions").header("Authorization","Bearer admin-fixture").contentType(MediaType.APPLICATION_JSON).content("{}")).andExpect(status().isForbidden());
  mvc.perform(patch("/api/v1/me").header("Authorization","Bearer admin-fixture").contentType(MediaType.APPLICATION_JSON).content("{} ")).andExpect(status().isForbidden());
  mvc.perform(get("/api/v1/me").header("Authorization","Bearer admin-fixture")).andExpect(status().isOk());
  mvc.perform(get("/api/v1/admin/summary").header("Authorization","Bearer admin-fixture")).andExpect(status().isOk());
 }
 String learnerBody(boolean suspended,long revision){return "{\"displayName\":\"Learner\",\"level\":\"A1\",\"dailyMinutes\":15,\"suspended\":"+suspended+",\"revision\":"+revision+"}";}
 @Test void suspensionIsEnforcedForExistingJwtAndCannotSuspendSelf()throws Exception{
  mvc.perform(patch("/api/v1/admin/learners/"+admin).header("Authorization","Bearer admin-fixture").contentType(MediaType.APPLICATION_JSON).content(learnerBody(true,0))).andExpect(status().isConflict());
  mvc.perform(patch("/api/v1/admin/learners/"+user).header("Authorization","Bearer admin-fixture").contentType(MediaType.APPLICATION_JSON).content(learnerBody(true,0))).andExpect(status().isOk()).andExpect(jsonPath("$.suspended").value(true));
  mvc.perform(get("/api/v1/me").header("Authorization","Bearer learner-fixture")).andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ACCOUNT_SUSPENDED"));
  mvc.perform(patch("/api/v1/admin/learners/"+user).header("Authorization","Bearer admin-fixture").contentType(MediaType.APPLICATION_JSON).content(learnerBody(false,0))).andExpect(status().isConflict());
  mvc.perform(patch("/api/v1/admin/learners/"+user).header("Authorization","Bearer admin-fixture").contentType(MediaType.APPLICATION_JSON).content(learnerBody(false,1))).andExpect(status().isOk());
  mvc.perform(get("/api/v1/me").header("Authorization","Bearer learner-fixture")).andExpect(status().isOk());
 }
 String scenario(boolean active,Long revision){return "{\"title\":\"Admin fixture scenario\",\"topicId\":\""+topic+"\",\"level\":\"A1\",\"description\":\"A real scenario\",\"aiRole\":\"Tutor\",\"userRole\":\"Learner\",\"estimatedMinutes\":10,\"active\":"+active+",\"samplePhrases\":[\"Hello\"],\"learningObjectives\":[\"Introduce yourself\"],\"revision\":"+revision+"}";}
 @Test void draftPublishHideAndStaleWriteAreConsistentWithPublicCatalog()throws Exception{
  UUID id=UUID.randomUUID();String route="/api/v1/admin/scenarios/"+id;
  mvc.perform(put(route).header("Authorization","Bearer learner-fixture").contentType(MediaType.APPLICATION_JSON).content(scenario(false,null))).andExpect(status().isForbidden());
  mvc.perform(put(route).header("Authorization","Bearer admin-fixture").contentType(MediaType.APPLICATION_JSON).content(scenario(false,null))).andExpect(status().isOk()).andExpect(jsonPath("$.revision").value(0));
  mvc.perform(get("/api/v1/scenarios/"+id)).andExpect(status().isNotFound());
  mvc.perform(put(route).header("Authorization","Bearer admin-fixture").contentType(MediaType.APPLICATION_JSON).content(scenario(true,0L))).andExpect(status().isOk());
  mvc.perform(get("/api/v1/scenarios/"+id)).andExpect(status().isOk());
  mvc.perform(put(route).header("Authorization","Bearer admin-fixture").contentType(MediaType.APPLICATION_JSON).content(scenario(false,0L))).andExpect(status().isConflict());
  mvc.perform(put(route).header("Authorization","Bearer admin-fixture").contentType(MediaType.APPLICATION_JSON).content(scenario(false,1L))).andExpect(status().isOk());
  mvc.perform(get("/api/v1/scenarios/"+id)).andExpect(status().isNotFound());
  assertEquals(3,audit.findAll().stream().filter(a->a.actorId.equals(admin)&&a.target.equals(id.toString())).count());
 }
 @Test void paginationValidationAndServiceResponseNeverExposeSecrets()throws Exception{
  mvc.perform(get("/api/v1/admin/learners?size=101").header("Authorization","Bearer admin-fixture")).andExpect(status().isBadRequest());
  mvc.perform(get("/api/v1/admin/scenarios?page=-1").header("Authorization","Bearer admin-fixture")).andExpect(status().isBadRequest());
  mvc.perform(get("/api/v1/admin/learners?q=learner@example.test&size=1").header("Authorization","Bearer admin-fixture")).andExpect(status().isOk()).andExpect(jsonPath("$.items.length()").value(1));
  String body=mvc.perform(get("/api/v1/admin/services").header("Authorization","Bearer admin-fixture")).andExpect(status().isOk()).andExpect(header().string("Cache-Control","no-store")).andReturn().getResponse().getContentAsString();
  assertFalse(body.contains("test-gemini-key"));assertFalse(body.contains("apiKey"));
 }
 @Test void invalidScenarioCannotCreateAuditAndLearnerCannotSelfPromote()throws Exception{
  long before=audit.count();
  mvc.perform(put("/api/v1/admin/scenarios/"+UUID.randomUUID()).header("Authorization","Bearer admin-fixture").contentType(MediaType.APPLICATION_JSON).content("{}")).andExpect(status().isBadRequest());assertEquals(before,audit.count());
  mvc.perform(patch("/api/v1/me").header("Authorization","Bearer learner-fixture").contentType(MediaType.APPLICATION_JSON).content("{\"displayName\":\"Test\",\"role\":\"admin\"}"));
  mvc.perform(get("/api/v1/admin/status").header("Authorization","Bearer learner-fixture")).andExpect(status().isForbidden());
 }
}
