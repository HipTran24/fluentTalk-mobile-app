package com.englishspeaking.ai.security;

import com.englishspeaking.ai.common.error.ApiErrorResponse;
import com.englishspeaking.ai.common.filter.RequestIdFilter;
import com.englishspeaking.ai.config.AppProperties;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.MediaType;
import org.springframework.http.HttpMethod;
import org.springframework.security.web.access.expression.WebExpressionAuthorizationManager;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;
import java.util.Map;

/**
 * Security configuration for Spring Boot backend.
 * Public endpoints: /api/v1/health and /error.
 * Admin endpoints: /api/v1/admin/** requires ROLE_ADMIN.
 * All other endpoints are fail-closed and require valid authentication.
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    private final AppProperties appProperties;
    private final ObjectMapper objectMapper;
    private final SupabaseJwtAuthenticationFilter jwtAuthenticationFilter;

    public SecurityConfig(AppProperties appProperties,
                          ObjectMapper objectMapper,
                          SupabaseJwtAuthenticationFilter jwtAuthenticationFilter) {
        this.appProperties = appProperties;
        this.objectMapper = objectMapper;
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/v1/health").permitAll()
                        .requestMatchers("/api/v1/topics", "/api/v1/scenarios/**").access(new WebExpressionAuthorizationManager("!hasRole('ADMIN')"))
                        .requestMatchers("/error").permitAll()
                        .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")
                        // Identity bootstrap is shared; learner mutations and learning APIs are exclusive.
                        .requestMatchers(HttpMethod.GET, "/api/v1/me").authenticated()
                        .anyRequest().access(new WebExpressionAuthorizationManager("hasRole('USER') and !hasRole('ADMIN')"))
                )
                .exceptionHandling(exceptions -> exceptions
                        .authenticationEntryPoint((request, response, authException) -> {
                            String requestId = RequestIdFilter.getRequestId(request);
                            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                            ApiErrorResponse error = new ApiErrorResponse(
                                    "UNAUTHENTICATED",
                                    "Authentication is required to access this resource",
                                    Map.of(),
                                    requestId
                            );
                            response.getWriter().write(objectMapper.writeValueAsString(error));
                        })
                        .accessDeniedHandler((request, response, accessDeniedException) -> {
                            String requestId = RequestIdFilter.getRequestId(request);
                            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                            ApiErrorResponse error = new ApiErrorResponse(
                                    "FORBIDDEN",
                                    "You do not have permission to access this resource",
                                    Map.of(),
                                    requestId
                            );
                            response.getWriter().write(objectMapper.writeValueAsString(error));
                        })
                )
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        List<String> origins = appProperties.getCors().getAllowedOrigins();
        if (origins != null && !origins.isEmpty()) {
            configuration.setAllowedOriginPatterns(List.of("*"));
        } else {
            configuration.setAllowedOriginPatterns(List.of("*"));
        }
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("Authorization", "Content-Type", "X-Request-Id", "Idempotency-Key"));
        configuration.setExposedHeaders(List.of("X-Request-Id"));
        configuration.setAllowCredentials(false);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}

