package com.englishspeaking.ai.admin;
import com.englishspeaking.ai.common.error.ApiException;
import com.englishspeaking.ai.config.AppProperties;
import com.englishspeaking.ai.profile.domain.Profile;
import com.englishspeaking.ai.profile.infrastructure.ProfileRepository;
import com.englishspeaking.ai.curriculum.model.*;
import com.englishspeaking.ai.curriculum.repository.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.data.domain.*;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import jakarta.validation.constraints.*;
import java.time.*;
import java.util.*;

@Service @Transactional
public class AdminService {
 @org.springframework.beans.factory.annotation.Autowired private com.englishspeaking.ai.provider.AiRuntimeConfig runtime;
 private final ProfileRepository profiles;private final ScenarioRepository scenarios;private final TopicRepository topics;
 private final AdminAuditRepository audit;private final JdbcTemplate jdbc;private final AppProperties config;private final ObjectMapper mapper;
 public AdminService(ProfileRepository p,ScenarioRepository s,TopicRepository t,AdminAuditRepository a,JdbcTemplate j,AppProperties c,ObjectMapper m){profiles=p;scenarios=s;topics=t;audit=a;jdbc=j;config=c;mapper=m;}
 public record Result<T>(List<T> items,long total,int page,int size,boolean hasMore){}
 private <T> Result<T> result(Page<T> p){return new Result<>(p.getContent(),p.getTotalElements(),p.getNumber(),p.getSize(),p.hasNext());}
 private Pageable page(int page,int size,String sort){if(page<0||size<1||size>100)throw bad("Phân trang không hợp lệ.");return PageRequest.of(page,size,Sort.by(sort).descending());}
 private String query(String q){if(q==null)return "";if(q.length()>100)throw bad("Từ khóa quá dài.");return q.trim().toLowerCase(Locale.ROOT);}
 private long count(String sql,Object...args){Long v=jdbc.queryForObject(sql,Long.class,args);return v==null?0:v;}
 @Transactional(readOnly=true) public Map<String,Object> summary(){
  Instant start=LocalDate.now(ZoneOffset.UTC).atStartOfDay(ZoneOffset.UTC).toInstant();
  List<Map<String,Object>> days=new ArrayList<>();
  for(int i=6;i>=0;i--){Instant from=start.minus(Duration.ofDays(i));days.add(Map.of("date",from.atZone(ZoneOffset.UTC).toLocalDate().toString(),"sessions",count("select count(*) from sessions where started_at>=? and started_at<?",java.sql.Timestamp.from(from),java.sql.Timestamp.from(from.plus(Duration.ofDays(1))))));}
  return Map.of("learners",profiles.count(),"suspendedLearners",count("select count(*) from profiles where suspended=true"),"scenarios",scenarios.count(),"activeScenarios",count("select count(*) from scenarios where active=true"),"completedSessions",count("select count(*) from sessions where status='completed'"),"completedMinutes",count("select coalesce(sum(duration_seconds),0) from sessions where status='completed'")/60,"topics",topics.count(),"weekly",days);
 }
 public record Learner(UUID id,String displayName,String email,String level,String goal,int dailyMinutes,boolean suspended,long revision,Instant createdAt){}
 private Learner learner(Profile p){return new Learner(p.getId(),p.getDisplayName(),p.getEmail(),p.getLevel(),p.getGoal(),p.getDailyMinutes(),p.isSuspended(),p.getRevision(),p.getCreatedAt());}
 @Transactional(readOnly=true) public Result<Learner> learners(String q,String level,int p,int size){
  if(level!=null&&!level.isBlank()&&!Set.of("A0","A1","A2","B1","B2","C1","C2").contains(level))throw bad("Trình độ không hợp lệ.");
  return result(profiles.searchAdmin(query(q),level==null?"":level,page(p,size,"createdAt")).map(this::learner));
 }
 public record LearnerEdit(@NotBlank @Size(max=80) String displayName,@NotBlank @Pattern(regexp="A0|A1|A2|B1|B2|C1|C2") String level,@Min(5) @Max(60) int dailyMinutes,@NotNull Boolean suspended,@NotNull @PositiveOrZero Long revision){}
 public Learner updateLearner(UUID actor,UUID id,LearnerEdit req){
  var p=profiles.findById(id).orElseThrow(this::missing);
  if(actor.equals(id)&&req.suspended())throw new ApiException("CONFLICT","Không thể khóa chính tài khoản quản trị đang dùng.",HttpStatus.CONFLICT);
  if(p.getRevision()!=req.revision())throw conflict();
  p.setDisplayName(req.displayName().trim());p.setLevel(req.level());p.setDailyMinutes(req.dailyMinutes());p.setSuspended(req.suspended());
  p=profiles.saveAndFlush(p);audit.save(new AdminAudit(actor,"learner.update",id.toString()));return learner(p);
 }
 public record ScenarioEdit(@NotBlank @Size(max=150) String title,@NotNull UUID topicId,@NotBlank @Pattern(regexp="A0|A1|A2|B1|B2|C1|C2") String level,
  @NotBlank @Size(max=4000) String description,@NotBlank @Size(max=100) String aiRole,@NotBlank @Size(max=100) String userRole,
  @Min(1) @Max(60) int estimatedMinutes,@NotNull Boolean active,@NotNull @Size(max=20) List<@NotBlank @Size(max=200) String> samplePhrases,
  @NotNull @Size(max=20) List<@NotBlank @Size(max=200) String> learningObjectives,Long revision){}
 public record ScenarioView(UUID id,String title,UUID topicId,String level,String description,String aiRole,String userRole,int estimatedMinutes,boolean active,List<String> samplePhrases,List<String> learningObjectives,long revision){}
 private List<String> strings(String json){try{return mapper.readValue(json,mapper.getTypeFactory().constructCollectionType(List.class,String.class));}catch(Exception e){return List.of();}}
 private ScenarioView scenario(Scenario s){return new ScenarioView(s.getId(),s.getTitle(),s.getTopicId(),s.getLevel(),s.getDescription(),s.getRoleAi(),s.getRoleUser(),s.getEstimatedMinutes(),s.isActive(),strings(s.getSamplePhrases()),strings(s.getLearningObjectives()),s.getRevision());}
 @Transactional(readOnly=true) public Result<ScenarioView> scenarios(String q,UUID topic,Boolean active,int p,int size){return result(scenarios.searchAdmin(query(q),topic,active,page(p,size,"updatedAt")).map(this::scenario));}
 public ScenarioView saveScenario(UUID actor,UUID id,ScenarioEdit req){
  var existing=scenarios.findById(id);if(existing.isPresent()&&(req.revision()==null||existing.get().getRevision()!=req.revision()))throw conflict();
  if(existing.isEmpty()&&req.revision()!=null)throw missing();
  if(!topics.existsById(req.topicId()))throw bad("Chủ đề không tồn tại.");
  var s=existing.orElseGet(()->new Scenario(id,req.topicId(),req.level(),req.title(),req.description(),req.aiRole(),req.userRole(),req.estimatedMinutes()));
  s.setTitle(req.title().trim());s.setTopicId(req.topicId());s.setLevel(req.level());s.setDescription(req.description().trim());s.setRoleAi(req.aiRole().trim());s.setRoleUser(req.userRole().trim());s.setEstimatedMinutes(req.estimatedMinutes());s.setActive(req.active());s.setUpdatedAt(Instant.now());
  try{s.setSamplePhrases(mapper.writeValueAsString(req.samplePhrases()));s.setLearningObjectives(mapper.writeValueAsString(req.learningObjectives()));}catch(Exception e){throw bad("Nội dung chưa hợp lệ.");}
  s=scenarios.saveAndFlush(s);audit.save(new AdminAudit(actor,existing.isPresent()?"scenario.update":"scenario.create",id.toString()));return scenario(s);
 }
 public record TopicEdit(@NotBlank @Pattern(regexp="[a-z0-9]+(?:-[a-z0-9]+)*") @Size(max=50) String slug,@NotBlank @Size(max=100) String title){}
 public Topic saveTopic(UUID actor,UUID id,TopicEdit req){
  if(topics.findAll().stream().anyMatch(t->!t.getId().equals(id)&&t.getSlug().equals(req.slug())))throw conflict();
  var t=topics.findById(id).orElseGet(()->new Topic(id,req.slug(),req.title()));t.setSlug(req.slug());t.setTitle(req.title().trim());
  topics.saveAndFlush(t);audit.save(new AdminAudit(actor,"topic.save",id.toString()));return t;
 }
 @Transactional(readOnly=true) public Result<AdminAudit> audit(int p,int size){return result(audit.findAll(page(p,size,"createdAt")));}
 @Transactional(readOnly=true) public Map<String,Object> services(){var text=runtime.current("text");var live=runtime.current("live");return Map.of("textConfigured",text.configured(),"liveConfigured",live.configured(),"textModel",text.model(),"liveModel",live.model(),"textConfig",runtime.view("text"),"liveConfig",runtime.view("live"),"dailyVoiceMinutes",config.getQuota().getDefaultDailyMinutes(),"maxDailyTextTurns",config.getQuota().getMaxDailyTurns(),"telemetry","Token chat được ghi từ metadata provider trong mục Sử dụng. Chưa đo token Live, chi phí hoặc số kết nối Live đang mở.");}
 private ApiException bad(String message){return new ApiException("VALIDATION_FAILED",message,HttpStatus.BAD_REQUEST);}
 private ApiException missing(){return new ApiException("NOT_FOUND","Không tìm thấy dữ liệu.",HttpStatus.NOT_FOUND);}
 private ApiException conflict(){return new ApiException("CONFLICT","Dữ liệu đã thay đổi hoặc bị trùng. Tải lại trước khi lưu.",HttpStatus.CONFLICT);}
}
