package com.englishspeaking.ai.provider;

import com.englishspeaking.ai.admin.*;
import com.englishspeaking.ai.common.error.ApiException;
import com.englishspeaking.ai.config.AppProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import javax.crypto.Cipher;
import javax.crypto.spec.*;
import java.security.SecureRandom;
import java.util.*;

@Service
public class AiRuntimeConfig {
    private final ProviderConfigurationRepository repository;
    private final AppProperties properties;
    private final AdminAuditRepository audit;
    private final byte[] masterKey;
    public AiRuntimeConfig(ProviderConfigurationRepository repository, AppProperties properties,
                          AdminAuditRepository audit,@Value("${AI_CONFIG_ENCRYPTION_KEY:}") String master) {
        this.repository=repository;this.properties=properties;this.audit=audit;
        byte[] decoded;
        try {decoded=Base64.getDecoder().decode(master);}catch(Exception e){decoded=new byte[0];}
        this.masterKey=decoded.length==32?decoded:new byte[0];
    }
    public record Snapshot(String provider,String model,@com.fasterxml.jackson.annotation.JsonIgnore String apiKey) {
        @Override public String toString(){return "ProviderSnapshot[credentials redacted]";}
        public boolean configured(){return !apiKey.isBlank()&&!model.isBlank();}
    }
    public record Edit(@NotBlank @Pattern(regexp="gemini|openai|groq") String provider,
                       @NotBlank @Pattern(regexp="[A-Za-z0-9][A-Za-z0-9._/-]{0,99}") String model,
                       @Size(max=3000) @JsonProperty(access=JsonProperty.Access.WRITE_ONLY) String apiKey,
                       @NotNull @Min(-1) Long revision) {
        @Override public String toString(){return "ProviderEdit[credentials redacted]";}
    }
    private void channel(String value){if(!Set.of("text","live").contains(value))throw bad("Kênh dịch vụ không hợp lệ.");}
    public Snapshot environment(String channel){channel(channel);var g=properties.getGemini();return new Snapshot("gemini",channel.equals("text")?g.getModel():g.getLiveModel(),g.getApiKey());}
    @Transactional(readOnly=true) public Snapshot current(String channel) {
        channel(channel);
        return repository.findById(channel).map(r->new Snapshot(r.provider,r.model,crypt(false,r.encryptedKey,channel))).orElseGet(()->environment(channel));
    }
    @Transactional(readOnly=true) public Map<String,Object> view(String channel) {
        channel(channel);var row=repository.findById(channel);var value=current(channel);
        return Map.of("provider",value.provider(),"model",value.model(),"keyConfigured",value.configured(),
            "revision",row.map(r->r.revision).orElse(-1L),"source",row.isPresent()?"database":"environment","editable",masterKey.length==32);
    }
    public Snapshot draft(String channel,Edit edit) {
        channel(channel);
        if(channel.equals("live")&&!edit.provider().equals("gemini"))throw bad("Live hiện hỗ trợ Gemini; provider chat được cấu hình riêng.");
        if(edit.provider().equals("gemini")&&!edit.model().matches("[A-Za-z0-9._-]{1,100}"))throw bad("Nhập model Gemini không có tiền tố models/.");
        var previous=current(channel);
        String key=edit.apiKey()==null?"":edit.apiKey().trim();
        if(key.isBlank()){
            if(!previous.provider().equals(edit.provider()))throw bad("Cần nhập key mới khi đổi provider.");
            key=previous.apiKey();
        }
        if(key.isBlank()||key.chars().anyMatch(c->c<33||c>126))throw bad("API key chưa hợp lệ.");
        return new Snapshot(edit.provider(),edit.model(),key);
    }
    @Transactional public Map<String,Object> save(UUID actor,String channel,Edit edit) {
        if(masterKey.length!=32)throw new ApiException("CONFIGURATION_REQUIRED","Máy chủ chưa có khóa mã hóa cấu hình.",HttpStatus.SERVICE_UNAVAILABLE);
        var row=repository.findById(channel);
        if(row.map(r->r.revision).orElse(-1L).longValue()!=edit.revision())throw conflict();
        var value=draft(channel,edit);
        var entity=row.orElseGet(()->{var c=new ProviderConfiguration();c.channel=channel;return c;});
        entity.provider=value.provider();entity.model=value.model();entity.encryptedKey=crypt(true,value.apiKey(),channel);
        repository.saveAndFlush(entity);audit.save(new AdminAudit(actor,"provider.update",channel));
        return view(channel);
    }
    @Transactional public Map<String,Object> reset(UUID actor,String channel,long revision) {
        channel(channel);var row=repository.findById(channel);
        if(row.map(r->r.revision).orElse(-1L)!=revision)throw conflict();
        row.ifPresent(repository::delete);repository.flush();audit.save(new AdminAudit(actor,"provider.reset",channel));return view(channel);
    }
    private String crypt(boolean encrypt,String value,String channel) {
        try {
            if(masterKey.length!=32)throw new IllegalStateException();
            var cipher=Cipher.getInstance("AES/GCM/NoPadding");byte[] nonce=new byte[12];
            byte[] payload;
            if(encrypt){new SecureRandom().nextBytes(nonce);payload=value.getBytes(java.nio.charset.StandardCharsets.UTF_8);}
            else {var all=Base64.getDecoder().decode(value);nonce=Arrays.copyOfRange(all,0,12);payload=Arrays.copyOfRange(all,12,all.length);}
            cipher.init(encrypt?Cipher.ENCRYPT_MODE:Cipher.DECRYPT_MODE,new SecretKeySpec(masterKey,"AES"),new GCMParameterSpec(128,nonce));
            cipher.updateAAD(channel.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            var result=cipher.doFinal(payload);
            if(!encrypt)return new String(result,java.nio.charset.StandardCharsets.UTF_8);
            var out=java.nio.ByteBuffer.allocate(nonce.length+result.length).put(nonce).put(result).array();return Base64.getEncoder().encodeToString(out);
        }catch(Exception e){throw new ApiException("CONFIGURATION_REQUIRED","Không thể đọc hoặc lưu key dịch vụ. Kiểm tra khóa mã hóa trên máy chủ.",HttpStatus.SERVICE_UNAVAILABLE);}
    }
    private ApiException bad(String message){return new ApiException("VALIDATION_FAILED",message,HttpStatus.BAD_REQUEST);}
    private ApiException conflict(){return new ApiException("CONFLICT","Cấu hình đã thay đổi. Tải lại trước khi lưu.",HttpStatus.CONFLICT);}
}
