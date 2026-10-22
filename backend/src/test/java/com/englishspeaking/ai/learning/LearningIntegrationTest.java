package com.englishspeaking.ai.learning;
import com.englishspeaking.ai.EnglishSpeakingAiApplication;
import com.englishspeaking.ai.security.*;
import com.englishspeaking.ai.conversation.domain.*;
import com.englishspeaking.ai.conversation.repository.*;
import com.englishspeaking.ai.profile.domain.Profile;
import com.englishspeaking.ai.profile.infrastructure.ProfileRepository;
import com.englishspeaking.ai.curriculum.model.Scenario;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.http.MediaType;
import java.time.Instant;
import java.util.*;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(classes=EnglishSpeakingAiApplication.class) @AutoConfigureMockMvc @ActiveProfiles("test")
class LearningIntegrationTest {
 @Autowired MockMvc mvc;
 @Autowired LearningService learning;
 @Autowired ProfileRepository profiles;
 @Autowired SessionRepository sessions;
 @Autowired MessageRepository messages;
 @Autowired VoiceLearningNoteRepository notes;
 @Autowired JdbcTemplate jdbc;
 @Autowired VoiceNoteRetention retention;
 @MockitoBean JwksJwtTokenVerifier verifier;
 UUID a,b;
 @BeforeEach void setup(){
  a=UUID.randomUUID();b=UUID.randomUUID();
  when(verifier.verify("fixture-a")).thenReturn(new AuthenticatedUser(a,"a@example.test",List.of("user")));
  when(verifier.verify("fixture-b")).thenReturn(new AuthenticatedUser(b,"b@example.test",List.of("user")));
  profiles.save(new Profile(a,"a@example.test","A")); profiles.save(new Profile(b,"b@example.test","B"));
 }
 LearningService.Settings settings(boolean enabled,boolean voice){return new LearningService.Settings(enabled,voice,"Interview practice",null,"Aoede");}
 @Test void endpointsRequireAuthentication()throws Exception{
  mvc.perform(get("/api/v1/me/learning")).andExpect(status().isUnauthorized());
  mvc.perform(post("/api/v1/me/learning/voice-notes").contentType(MediaType.APPLICATION_JSON).content("{}" )).andExpect(status().isUnauthorized());
 }
 @Test void disabledPersonalizationDoesNotReadHistoryOrCreateFakeEvidence(){
  var result=learning.dashboard(a);assertFalse(result.settings().enabled());assertTrue(result.evidence().isEmpty());assertTrue(result.recommendations().isEmpty());assertEquals("",learning.tutorContext(a));
 }
 @Test void evidenceAndTutorContextNeverIncludeAnotherAccount()throws Exception{
  var sa=sessions.save(new SessionEntity(a,null,"text","A1"));var sb=sessions.save(new SessionEntity(b,null,"text","A1"));
  messages.save(new MessageEntity(sa.getId(),"user","I want to practice an interview",1,null,null));
  messages.save(new MessageEntity(sb.getId(),"user","OTHER_ACCOUNT_PRIVATE_MARKER",1,null,null));
  learning.update(a,settings(true,false));
  var result=learning.dashboard(a);assertEquals(1,result.textSamples());assertEquals(sa.getId(),result.evidence().getFirst().sessionId());
  assertFalse(result.toString().contains("OTHER_ACCOUNT_PRIVATE_MARKER"));
  assertTrue(learning.tutorContext(a).contains("Interview practice"));assertFalse(learning.tutorContext(a).contains("OTHER_ACCOUNT_PRIVATE_MARKER"));
  mvc.perform(get("/api/v1/me/learning").header("Authorization","Bearer fixture-b"))
   .andExpect(status().isOk()).andExpect(jsonPath("$.settings.enabled").value(false)).andExpect(jsonPath("$.textSamples").value(0));
 }
 @Test void voiceMemoryRequiresConsentOwnershipAndIsIdempotentAndRevocable()throws Exception{
  jdbc.execute("create table if not exists live_voice_access(id uuid primary key,user_id uuid,usage_day date,reserved_seconds integer,issued_at timestamp with time zone)");
  UUID call=UUID.randomUUID();jdbc.update("insert into live_voice_access(id,user_id,issued_at) values(?,?,?)",call,a,java.sql.Timestamp.from(Instant.now()));
  String body="{\"sessionId\":\""+call+"\",\"transcript\":\"I would like to practice English\"}";
  learning.update(a,settings(true,false));
  mvc.perform(post("/api/v1/me/learning/voice-notes").header("Authorization","Bearer fixture-a").contentType(MediaType.APPLICATION_JSON).content(body)).andExpect(status().isConflict());
  learning.update(a,settings(true,true));learning.update(b,settings(true,true));
  mvc.perform(post("/api/v1/me/learning/voice-notes").header("Authorization","Bearer fixture-b").contentType(MediaType.APPLICATION_JSON).content(body)).andExpect(status().isNotFound());
  for(int i=0;i<2;i++)mvc.perform(post("/api/v1/me/learning/voice-notes").header("Authorization","Bearer fixture-a").contentType(MediaType.APPLICATION_JSON).content(body)).andExpect(status().isNoContent());
  assertEquals(1,learning.dashboard(a).voiceSamples());assertEquals(0,learning.dashboard(b).voiceSamples());
  learning.update(a,settings(true,false));assertFalse(notes.existsById(call));
 }
 @Test void voiceNotesExpireAfterThirtyDays(){
  var old=new VoiceLearningNote();old.id=UUID.randomUUID();old.userId=a;old.transcript="old";old.createdAt=Instant.now().minusSeconds(31*86400L);notes.save(old);
  var fresh=new VoiceLearningNote();fresh.id=UUID.randomUUID();fresh.userId=a;fresh.transcript="fresh";notes.save(fresh);
  retention.purge();assertFalse(notes.existsById(old.id));assertTrue(notes.existsById(fresh.id));
 }
 @Test void recommendationsRankExplicitLevelInterestAndNoveltyWithoutScores(){
  UUID topic=UUID.randomUUID();
  Scenario newMatch=new Scenario(UUID.randomUUID(),topic,"A1","New","D","Tutor","Learner",10);
  Scenario oldMatch=new Scenario(UUID.randomUUID(),topic,"A1","Old","D","Tutor","Learner",10);
  Scenario wrongLevel=new Scenario(UUID.randomUUID(),topic,"C2","Advanced","D","Tutor","Learner",10);
  Set<UUID> practiced=Set.of(oldMatch.getId());
  assertTrue(LearningService.rank(newMatch,"A1",topic,practiced)>LearningService.rank(oldMatch,"A1",topic,practiced));
  assertTrue(LearningService.rank(oldMatch,"A1",topic,practiced)>LearningService.rank(wrongLevel,"A1",topic,practiced));
 }
 @Test void dailyPlanUsesOnlyCompletedSessionsAndMatchesRemainingBudget(){
  learning.update(a,settings(true,false));
  var session=new SessionEntity(a,null,"text","A1");session.setStatus("completed");session.setEndedAt(Instant.now());session.setDurationSeconds(300);sessions.save(session);
  var active=new SessionEntity(a,null,"text","A1");active.setDurationSeconds(6000);sessions.save(active);
  var result=learning.dashboard(a);assertEquals(5,result.todayMinutes());assertEquals(10,result.remainingMinutes());
  assertEquals(10,result.plan().stream().mapToInt(LearningService.PlanStep::minutes).sum());
 }
}
