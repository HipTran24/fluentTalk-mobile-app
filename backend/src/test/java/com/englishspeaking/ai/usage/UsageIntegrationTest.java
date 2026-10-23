package com.englishspeaking.ai.usage;
import com.englishspeaking.ai.EnglishSpeakingAiApplication;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(classes=EnglishSpeakingAiApplication.class) @ActiveProfiles("test")
class UsageIntegrationTest {
 @Autowired UsageMeter meter;@Autowired UsageEventRepository repository;@Autowired UsageAnalytics analytics;@Autowired PlatformTransactionManager transactions;
 @BeforeEach void before(){repository.deleteAll();}
 @AfterEach void after(){repository.deleteAll();}
 @Test void parsesProviderTokensWithoutInventingMissingValues()throws Exception{
  var mapper=new ObjectMapper();
  var gemini=UsageMeter.parse("gemini",mapper.readTree("{\"usageMetadata\":{\"promptTokenCount\":100,\"candidatesTokenCount\":20,\"totalTokenCount\":125,\"thoughtsTokenCount\":5,\"cachedContentTokenCount\":30}}"));
  assertEquals(125L,gemini.total());assertEquals(5L,gemini.reasoning());assertEquals(30L,gemini.cached());
  for(String provider:List.of("openai","groq")){
   var usage=UsageMeter.parse(provider,mapper.readTree("{\"usage\":{\"prompt_tokens\":100,\"completion_tokens\":20,\"total_tokens\":120,\"prompt_tokens_details\":{\"cached_tokens\":30},\"completion_tokens_details\":{\"reasoning_tokens\":5}}}"));
   assertEquals(120L,usage.total());assertEquals(5L,usage.reasoning());
  }
  assertNull(UsageMeter.parse("gemini",mapper.readTree("{}")).total());
  var bad=UsageMeter.parse("groq",mapper.readTree("{\"usage\":{\"total_tokens\":-1,\"prompt_tokens\":\"10\",\"completion_tokens\":1.5}}"));
  assertNull(bad.total());assertNull(bad.input());assertNull(bad.output());
 }
 @Test void aggregatesDatesProvidersAndUnknownsAndFillsEmptyDays(){
  meter.record("gemini","model-a","chat","success",200,45,new UsageMeter.Tokens(100L,20L,125L,30L,5L));
  meter.record("groq","model-b","check","error",429,10,null);
  var old=new UsageEvent();old.provider="gemini";old.model="old";old.purpose="chat";old.outcome="success";old.usageDay=LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).minusDays(10);old.totalTokens=999L;repository.saveAndFlush(old);
  var report=analytics.read(7,"");var totals=(Map<?,?>)report.get("totals");
  assertEquals(2L,totals.get("requests"));assertEquals(1L,totals.get("errors"));assertEquals(1L,totals.get("unknownUsage"));assertEquals(1L,totals.get("checks"));assertEquals(125L,totals.get("totalTokens"));
  assertEquals(7,((List<?>)report.get("daily")).size());assertEquals(2,((List<?>)report.get("models")).size());
  var filtered=(Map<?,?>)analytics.read(7,"gemini").get("totals");assertEquals(1L,filtered.get("requests"));assertEquals(0L,filtered.get("unknownUsage"));
  assertThrows(com.englishspeaking.ai.common.error.ApiException.class,()->analytics.read(91,""));
  assertThrows(com.englishspeaking.ai.common.error.ApiException.class,()->analytics.read(7,"invalid"));
 }
 @Test void metricsSurviveOuterTransactionRollback(){
  new TransactionTemplate(transactions).execute(status->{meter.record("gemini","model","chat","error",200,1,new UsageMeter.Tokens(1L,2L,3L,null,null));status.setRollbackOnly();return null;});
  assertEquals(1,repository.count());
 }
}
