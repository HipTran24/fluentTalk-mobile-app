package com.englishspeaking.ai.security;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.io.Serializable;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

/**
 * Immutable authenticated user representation extracted from verified Supabase JWT claims.
 * Client-submitted user IDs are strictly ignored in favor of the verified subject.
 */
public record AuthenticatedUser(
        UUID id,
        String email,
        List<String> roles
) implements Serializable {

    public Collection<? extends GrantedAuthority> getAuthorities() {
        return roles.stream()
                .map(r -> r.toUpperCase(java.util.Locale.ROOT))
                .map(r -> r.startsWith("ROLE_") ? r : "ROLE_" + r)
                .map(SimpleGrantedAuthority::new)
                .toList();
    }

    public boolean hasRole(String role) {
        String cleanRole = role.startsWith("ROLE_") ? role.substring(5) : role;
        return roles.stream().anyMatch(r -> r.equalsIgnoreCase(cleanRole) || r.equalsIgnoreCase("ROLE_" + cleanRole));
    }
}
