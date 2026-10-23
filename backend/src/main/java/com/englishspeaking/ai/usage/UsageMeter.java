package com.englishspeaking.ai.usage;

import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;

@Service
public class UsageMeter {
 private final UsageEventRepository repository;
 public UsageMeter(UsageEventRepository repository){this.repository=repository;}
 public record Tokens(Long input,Long output,Long total,Long cached,Long reasoning) {}
 private static Long number(JsonNode parent,String key){var n=parent.path(key);return n.isIntegralNumber()&&n.canConvertToLong()&&n.longValue()>=0&&n.longValue()<=1_000_000_000L?n.longValue():null;}
 public static Tokens parse(String provider,JsonNode body){
  if(provider.equals("gemini")){
   var u=body.path("usageMetadata");return new Tokens(number(u,"promptTokenCount"),number(u,"candidatesTokenCount"),number(u,"totalTokenCount"),number(u,"cachedContentTokenCount"),number(u,"thoughtsTokenCount"));
  }
  var u=body.path("usage");return new Tokens(number(u,"prompt_tokens"),number(u,"completion_tokens"),number(u,"total_tokens"),number(u.path("prompt_tokens_details"),"cached_tokens"),number(u.path("completion_tokens_details"),"reasoning_tokens"));
 }
 // Independent transaction: upstream usage survives a subsequent chat transaction rollback.
 @Transactional(propagation=Propagation.REQUIRES_NEW)
 public void record(String provider,String model,String purpose,String outcome,Integer status,long durationMs,Tokens tokens){
  var e=new UsageEvent();e.provider=provider;e.model=model;e.purpose=purpose;e.outcome=outcome;e.httpStatus=status;e.durationMs=Math.max(0,durationMs);
  if(tokens!=null){e.inputTokens=tokens.input();e.outputTokens=tokens.output();e.totalTokens=tokens.total();e.cachedTokens=tokens.cached();e.reasoningTokens=tokens.reasoning();}
  repository.saveAndFlush(e);
 }
}
