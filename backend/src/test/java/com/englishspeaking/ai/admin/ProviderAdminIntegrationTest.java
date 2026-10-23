package com.englishspeaking.ai.admin;

import com.englishspeaking.ai.EnglishSpeakingAiApplication;
import com.englishspeaking.ai.provider.*;
import com.englishspeaking.ai.security.*;
import com.englishspeaking.ai.conversation.service.ConversationAiService;
import com.englishspeaking.ai.ai.LiveTokenProvider;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.context.*;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.http.MediaType;
import java.util.*;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(classes=EnglishSpeakingAiApplication.class) @AutoConfigureMockMvc @ActiveProfiles("test")
@TestPropertySource(properties="AI_CONFIG_ENCRYPTION_KEY=MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=")
class ProviderAdminIntegrationTest {
 @Autowired MockMvc mvc;@Autowired ProviderConfigurationRepository repository;@Autowired AiRuntimeConfig runtime;@Autowired AdminAuditRepository audit;
 @MockitoBean JwksJwtTokenVerifier verifier;
 @MockitoBean ConversationAiService text;
 @MockitoBean LiveTokenProvider live;
 UUID actor;
 @BeforeEach void setup(){repository.deleteAll();actor=UUID.randomUUID();when(verifier.verify("provider-admin")).thenReturn(new AuthenticatedUser(actor,"admin@example.test",List.of("ADMIN")));when(verifier.verify("provider-user")).thenReturn(new AuthenticatedUser(UUID.randomUUID(),"user@example.test",List.of("USER")));}
 @AfterEach void cleanup(){repository.deleteAll();}
 String body(String provider,String model,String key,long revision){return "{\"provider\":\""+provider+"\",\"model\":\""+model+"\",\"apiKey\":\""+key+"\",\"revision\":"+revision+"}";}
 @Test void encryptedPersistenceNoSecretEchoKeyRetentionAndReset()throws Exception{
  String key="test-only-provider-secret";
  String response=mvc.perform(put("/api/v1/admin/providers/text").header("Authorization","Bearer provider-admin").contentType(MediaType.APPLICATION_JSON).content(body("groq","example-model",key,-1))).andExpect(status().isOk()).andExpect(jsonPath("$.revision").value(0)).andExpect(header().string("Cache-Control","no-store")).andReturn().getResponse().getContentAsString();
  assertFalse(response.contains(key));assertFalse(response.contains("apiKey"));
  assertFalse(repository.findById("text").orElseThrow().encryptedKey.contains(key));
  assertEquals(key,runtime.current("text").apiKey());
  assertEquals("gemini",runtime.current("live").provider());
  mvc.perform(put("/api/v1/admin/providers/text").header("Authorization","Bearer provider-admin").contentType(MediaType.APPLICATION_JSON).content(body("groq","another-model","",0))).andExpect(status().isOk()).andExpect(jsonPath("$.revision").value(1));
  assertEquals(key,runtime.current("text").apiKey());
  mvc.perform(put("/api/v1/admin/providers/text").header("Authorization","Bearer provider-admin").contentType(MediaType.APPLICATION_JSON).content(body("groq","stale","",0))).andExpect(status().isConflict());
  assertEquals("another-model",runtime.current("text").model());
  mvc.perform(post("/api/v1/admin/providers/text/reset").header("Authorization","Bearer provider-admin").contentType(MediaType.APPLICATION_JSON).content("{\"revision\":1}")).andExpect(status().isOk()).andExpect(jsonPath("$.source").value("environment"));
  assertEquals("gemini",runtime.current("text").provider());
  assertEquals(3,audit.findAll().stream().filter(a->a.actorId.equals(actor)).count());
 }
 @Test void switchingProviderRequiresNewKeyAndLiveRejectsOtherProtocols()throws Exception{
  for(String channel:List.of("text","live")){
   mvc.perform(put("/api/v1/admin/providers/"+channel).header("Authorization","Bearer provider-admin").contentType(MediaType.APPLICATION_JSON).content(body("openai","model","",-1))).andExpect(status().isBadRequest());
  }
  mvc.perform(put("/api/v1/admin/providers/live").header("Authorization","Bearer provider-admin").contentType(MediaType.APPLICATION_JSON).content(body("openai","model","fake-new-key",-1))).andExpect(status().isBadRequest());
  mvc.perform(put("/api/v1/admin/providers/text").header("Authorization","Bearer provider-admin").contentType(MediaType.APPLICATION_JSON).content(body("custom","https://localhost","fake-new-key",-1))).andExpect(status().isBadRequest());
  assertTrue(repository.findAll().isEmpty());
 }
 @Test void allProviderMutationsRequireAdminAndProbeDoesNotPersist()throws Exception{
  for(String suffix:List.of("","/check","/reset")){
   var a=suffix.isEmpty()?put("/api/v1/admin/providers/text"):post("/api/v1/admin/providers/text"+suffix);
   mvc.perform(a.contentType(MediaType.APPLICATION_JSON).content(body("gemini","model","",-1))).andExpect(status().isUnauthorized());
   var b=suffix.isEmpty()?put("/api/v1/admin/providers/text"):post("/api/v1/admin/providers/text"+suffix);
   mvc.perform(b.header("Authorization","Bearer provider-user").contentType(MediaType.APPLICATION_JSON).content(body("gemini","model","",-1))).andExpect(status().isForbidden());
  }
  mvc.perform(post("/api/v1/admin/providers/text/check").header("Authorization","Bearer provider-admin").contentType(MediaType.APPLICATION_JSON).content(body("openai","test-model","new-test-key",-1))).andExpect(status().isOk()).andExpect(jsonPath("$.ok").value(true));
  verify(text).generateConfigured(anyString(),eq("A1"),isNull(),eq(List.of()),eq(""),argThat(v->v.provider().equals("openai")&&v.apiKey().equals("new-test-key")));
  assertTrue(repository.findAll().isEmpty());
 }
}
