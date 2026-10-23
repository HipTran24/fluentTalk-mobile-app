package com.englishspeaking.ai.security;

import com.englishspeaking.ai.common.error.ApiErrorResponse;
import com.englishspeaking.ai.common.filter.RequestIdFilter;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Map;

/**
 * Filter that parses and verifies incoming Supabase Bearer JWT tokens.
 * Extracts the user subject UUID and assigns authenticated principal.
 */
@Component
public class SupabaseJwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenVerifier jwtTokenVerifier;
    private final ObjectMapper objectMapper;

    public SupabaseJwtAuthenticationFilter(JwtTokenVerifier jwtTokenVerifier, ObjectMapper objectMapper) {
        this.jwtTokenVerifier = jwtTokenVerifier;
        this.objectMapper = objectMapper;
    }

    @org.springframework.beans.factory.annotation.Autowired
    private com.englishspeaking.ai.profile.infrastructure.ProfileRepository profiles;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String authHeader = request.getHeader("Authorization");

        if (StringUtils.hasText(authHeader) && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7).trim();
            try {
                AuthenticatedUser user = jwtTokenVerifier.verify(token);
                if (profiles.findById(user.id()).map(p->p.isSuspended()).orElse(false)) {
                    response.setStatus(403);response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                    response.getWriter().write(objectMapper.writeValueAsString(new ApiErrorResponse("ACCOUNT_SUSPENDED","Tài khoản đang bị tạm khóa. Vui lòng liên hệ quản trị viên.",Map.of(),RequestIdFilter.getRequestId(request))));return;
                }
                UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                        user,
                        null,
                        user.getAuthorities()
                );
                SecurityContextHolder.getContext().setAuthentication(authentication);
            } catch (JwtValidationException e) {
                SecurityContextHolder.clearContext();
                sendUnauthenticatedError(request, response, e.getMessage());
                return;
            }
        }

        filterChain.doFilter(request, response);
    }

    private void sendUnauthenticatedError(HttpServletRequest request, HttpServletResponse response, String message) throws IOException {
        String requestId = RequestIdFilter.getRequestId(request);
        response.setStatus(HttpStatus.UNAUTHORIZED.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        ApiErrorResponse error = new ApiErrorResponse(
                "UNAUTHENTICATED",
                message != null ? message : "Invalid or missing authentication token",
                Map.of(),
                requestId
        );
        response.getWriter().write(objectMapper.writeValueAsString(error));
    }
}
