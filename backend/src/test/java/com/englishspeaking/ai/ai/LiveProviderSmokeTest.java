package com.englishspeaking.ai.ai;
import com.englishspeaking.ai.config.AppProperties;
import com.englishspeaking.ai.conversation.service.ConversationAiService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import java.net.*;
import java.net.http.*;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;
import static org.junit.jupiter.api.Assertions.*;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

/** Opt-in provider smoke. Uses synthetic text only; never captures a microphone. */
class LiveProviderSmokeTest {
    @Test void actualTextAndNativeAudioProvider() throws Exception {
        assumeTrue("true".equals(System.getenv("LIVE_PROVIDER_SMOKE")));
        var props = new AppProperties();
        props.getGemini().setApiKey(System.getenv("GEMINI_API_KEY"));
        props.getGemini().setModel(System.getenv("GEMINI_MODEL"));
        props.getGemini().setLiveModel(System.getenv("GEMINI_LIVE_MODEL"));
        var mapper = new ObjectMapper();
        var text = new ConversationAiService(props,mapper).generateTurn("Hello! What is your name? Please ask me one easy question about my day.", "A1", null, List.of());
        assertFalse(text.text().isBlank());
        assertTrue(text.text().toLowerCase().contains("tom"));
        System.out.println("Real text provider: response received (characters=" + text.text().length()+")");
        var ticket = new LiveTokenProvider(props,mapper).issue("Aoede","A1");
        var complete = new CompletableFuture<Void>();
        var bytes = new AtomicInteger();
        var transcript = new AtomicInteger();
        var listener = new WebSocket.Listener() {
            final StringBuilder buffer = new StringBuilder();
            void parse(WebSocket socket, String chunk, boolean last) {
                buffer.append(chunk); if (!last) return;
                try {
                    var msg = mapper.readTree(buffer.toString()); buffer.setLength(0);
                    if (msg.has("setupComplete")) socket.sendText(mapper.writeValueAsString(Map.of("realtimeInput",Map.of("text","Say hello warmly and ask how my day was. Speak only two short sentences."))),true);
                    var content = msg.path("serverContent");
                    for (var part:content.path("modelTurn").path("parts")) {
                        var inline = part.path("inlineData");
                        if (inline.path("mimeType").asText().startsWith("audio/pcm")) bytes.addAndGet(Base64.getDecoder().decode(inline.path("data").asText()).length);
                    }
                    transcript.addAndGet(content.path("outputTranscription").path("text").asText().length());
                    if (bytes.get()>0 && transcript.get()>0 && content.path("turnComplete").asBoolean()) complete.complete(null);
                    if (msg.has("error")) complete.completeExceptionally(new IllegalStateException("Provider rejected Live setup"));
                } catch (Exception e) { complete.completeExceptionally(e); }
            }
            public CompletionStage<?> onText(WebSocket socket, CharSequence data, boolean last) { parse(socket,data.toString(),last);socket.request(1);return null; }
            public CompletionStage<?> onBinary(WebSocket socket, ByteBuffer data, boolean last) {
                parse(socket,StandardCharsets.UTF_8.decode(data).toString(),last);socket.request(1);return null;
            }
            public CompletionStage<?> onClose(WebSocket socket, int status, String reason) {
                if (!complete.isDone()) complete.completeExceptionally(new IllegalStateException("Live closed with code " + status)); return null;
            }
            public void onError(WebSocket socket, Throwable error) { complete.completeExceptionally(new IllegalStateException("Live transport failed")); }
        };
        String url = "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContentConstrained?access_token="
            + URLEncoder.encode(ticket.token(),StandardCharsets.UTF_8);
        WebSocket socket=null;
        try {
            socket=HttpClient.newHttpClient().newWebSocketBuilder().buildAsync(URI.create(url),listener).get(20,TimeUnit.SECONDS);
            socket.sendText(mapper.writeValueAsString(Map.of("setup",ticket.setup())),true).join();
            complete.get(45,TimeUnit.SECONDS);
            assertTrue(bytes.get()>0); assertTrue(transcript.get()>0);
            System.out.println("Real Live provider: PCM bytes="+bytes.get()+", transcript characters="+transcript.get());
        } finally { if(socket!=null) socket.abort(); }
    }
}
