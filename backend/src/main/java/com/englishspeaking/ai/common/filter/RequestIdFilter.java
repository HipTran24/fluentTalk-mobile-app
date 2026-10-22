package com.englishspeaking.ai.common.filter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.MDC;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;
import java.util.regex.Pattern;

/**
 * Filter that attaches a correlation / request ID to every HTTP request.
 * Sets the ID in MDC, request attributes, and HTTP response headers.
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class RequestIdFilter extends OncePerRequestFilter {

    public static final String REQUEST_ID_HEADER = "X-Request-Id";
    public static final String MDC_KEY = "requestId";
    public static final String REQUEST_ID_ATTRIBUTE = "com.englishspeaking.ai.requestId";

    private static final Pattern SAFE_ID_PATTERN = Pattern.compile("^[a-zA-Z0-9_-]{1,64}$");

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String requestId = request.getHeader(REQUEST_ID_HEADER);

        if (!StringUtils.hasText(requestId) || !SAFE_ID_PATTERN.matcher(requestId.trim()).matches()) {
            requestId = UUID.randomUUID().toString();
        } else {
            requestId = requestId.trim();
        }

        MDC.put(MDC_KEY, requestId);
        request.setAttribute(REQUEST_ID_ATTRIBUTE, requestId);
        response.setHeader(REQUEST_ID_HEADER, requestId);

        try {
            filterChain.doFilter(request, response);
        } finally {
            MDC.remove(MDC_KEY);
        }
    }

    public static String getRequestId(HttpServletRequest request) {
        if (request != null) {
            Object id = request.getAttribute(REQUEST_ID_ATTRIBUTE);
            if (id instanceof String s && StringUtils.hasText(s)) {
                return s;
            }
        }
        String mdc = MDC.get(MDC_KEY);
        return StringUtils.hasText(mdc) ? mdc : UUID.randomUUID().toString();
    }
}
