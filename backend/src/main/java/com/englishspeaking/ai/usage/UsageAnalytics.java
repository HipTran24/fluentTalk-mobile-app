package com.englishspeaking.ai.usage;

import com.englishspeaking.ai.common.error.ApiException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.util.*;

@Service
public class UsageAnalytics {
 private final JdbcTemplate jdbc;
 public UsageAnalytics(JdbcTemplate jdbc){this.jdbc=jdbc;}
 private static final String AGG="count(*) requests, sum(case when outcome<>'success' then 1 else 0 end) errors, sum(case when total_tokens is null then 1 else 0 end) unknown_usage, sum(case when purpose='check' then 1 else 0 end) checks, coalesce(sum(input_tokens),0) input_tokens, coalesce(sum(output_tokens),0) output_tokens, coalesce(sum(total_tokens),0) total_tokens, coalesce(sum(cached_tokens),0) cached_tokens, coalesce(sum(reasoning_tokens),0) reasoning_tokens";
 private static final List<String> KEYS=List.of("requests","errors","unknownUsage","checks","inputTokens","outputTokens","totalTokens","cachedTokens","reasoningTokens");
 private Map<String,Object> metrics(java.sql.ResultSet r)throws java.sql.SQLException {
  var m=new LinkedHashMap<String,Object>();for(int i=0;i<KEYS.size();i++)m.put(KEYS.get(i),r.getLong(i+1));return m;
 }
 @Transactional(readOnly=true) public Map<String,Object> read(int days,String provider){
  if(days<1||days>90||!Set.of("","gemini","openai","groq").contains(provider))throw new ApiException("VALIDATION_FAILED","Khoảng ngày hoặc provider không hợp lệ.",HttpStatus.BAD_REQUEST);
  LocalDate end=LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")),start=end.minusDays(days-1);
  var totals=new LinkedHashMap<String,Object>();for(String k:KEYS)totals.put(k,0L);
  String where=" from ai_usage_events where usage_day>=? and usage_day<=? and (?='' or provider=?)";
  var rows=jdbc.query("select "+AGG+", usage_day"+where+" group by usage_day order by usage_day",(r,n)->{var m=metrics(r);m.put("date",r.getDate(10).toLocalDate().toString());return m;},start,end,provider,provider);
  var byDate=new HashMap<String,Map<String,Object>>();for(var row:rows)byDate.put(row.get("date").toString(),row);
  var daily=new ArrayList<Map<String,Object>>();
  for(var date=start;!date.isAfter(end);date=date.plusDays(1)){
   var row=byDate.get(date.toString());if(row==null){row=new LinkedHashMap<>();row.put("date",date.toString());for(String k:KEYS)row.put(k,0L);}
   daily.add(row);for(String k:KEYS)totals.put(k,(long)totals.get(k)+(long)row.get(k));
  }
  var models=jdbc.query("select "+AGG+", provider, model"+where+" group by provider,model order by total_tokens desc limit 100",(r,n)->{var m=metrics(r);m.put("provider",r.getString(10));m.put("model",r.getString(11));return m;},start,end,provider,provider);
  return Map.of("timezone","Asia/Ho_Chi_Minh","from",start.toString(),"to",end.toString(),"totals",totals,"daily",daily,"models",models,"coverage","Token chat từ metadata provider; bao gồm kiểm tra kết nối. Live trực tiếp chưa đo token. Không có dữ liệu hồi tố trước khi bật đo.");
 }
}
