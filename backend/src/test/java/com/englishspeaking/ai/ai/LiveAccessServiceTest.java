package com.englishspeaking.ai.ai;
import com.englishspeaking.ai.common.error.ApiException;
import com.englishspeaking.ai.config.AppProperties;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import java.util.UUID;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.*;
class LiveAccessServiceTest {
    @Test void exhaustedDailyBudgetNeverMintsAnotherToken() {
        var provider = mock(LiveTokenProvider.class); var jdbc = mock(JdbcTemplate.class);
        when(provider.configured()).thenReturn(true);
        when(jdbc.queryForObject(anyString(), eq(Integer.class), any(), any())).thenReturn(900);
        var service = new LiveAccessService(provider, jdbc, new AppProperties());
        assertEquals("QUOTA_EXCEEDED", assertThrows(ApiException.class, () -> service.issue(UUID.randomUUID(), "Aoede", "A1")).getCode());
        verify(provider, never()).issue(anyString(), anyString());
    }
    @Test void providerFailureDoesNotWriteAReservation() {
        var provider = mock(LiveTokenProvider.class); var jdbc = mock(JdbcTemplate.class);
        when(provider.configured()).thenReturn(true);
        when(jdbc.queryForObject(anyString(), eq(Integer.class), any(), any())).thenReturn(0);
        when(provider.issue(anyString(), anyString())).thenThrow(new RuntimeException("upstream"));
        var service = new LiveAccessService(provider, jdbc, new AppProperties());
        assertThrows(RuntimeException.class, () -> service.issue(UUID.randomUUID(), "Aoede", "A1"));
        verify(jdbc, never()).update(anyString(), any(Object[].class));
    }
}
