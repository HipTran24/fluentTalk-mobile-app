package com.englishspeaking.ai.security;

import com.englishspeaking.ai.config.AppProperties;
import com.nimbusds.jose.JWSVerifier;
import com.nimbusds.jose.crypto.ECDSAVerifier;
import com.nimbusds.jose.crypto.RSASSAVerifier;
import com.nimbusds.jose.jwk.ECKey;
import com.nimbusds.jose.jwk.JWK;
import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.jwk.source.RemoteJWKSet;
import com.nimbusds.jose.proc.SecurityContext;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import java.net.URL;
import java.util.*;

@Component
public class JwksJwtTokenVerifier implements JwtTokenVerifier {

    private static final Logger log = LoggerFactory.getLogger(JwksJwtTokenVerifier.class);

    private final AppProperties appProperties;
    private JWKSource<SecurityContext> jwkSource;
    private JWKSet testJwkSet;

    public JwksJwtTokenVerifier(AppProperties appProperties) {
        this.appProperties = appProperties;
        initJwkSource();
    }

    public void setTestJwkSet(JWKSet testJwkSet) {
        this.testJwkSet = testJwkSet;
    }

    private synchronized void initJwkSource() {
        String jwksUrl = appProperties.getSupabase().getJwksUrl();
        if (StringUtils.hasText(jwksUrl)) {
            try {
                this.jwkSource = new RemoteJWKSet<>(new URL(jwksUrl));
                log.info("Initialized Supabase RemoteJWKSet with URL: {}", jwksUrl);
            } catch (Exception e) {
                log.warn("Could not initialize RemoteJWKSet with URL {}: {}", jwksUrl, e.getMessage());
            }
        }
    }

    @Override
    public AuthenticatedUser verify(String token) {
        if (!StringUtils.hasText(token)) {
            throw new JwtValidationException("Missing token");
        }

        SignedJWT signedJWT;
        try {
            signedJWT = SignedJWT.parse(token);
        } catch (Exception e) {
            throw new JwtValidationException("Malformed JWT token: " + e.getMessage(), e);
        }

        JWTClaimsSet claims;
        try {
            claims = signedJWT.getJWTClaimsSet();
        } catch (Exception e) {
            throw new JwtValidationException("Cannot extract JWT claims: " + e.getMessage(), e);
        }

        // 1. Validate Expiration
        Date exp = claims.getExpirationTime();
        if (exp == null || exp.before(new Date())) {
            throw new JwtValidationException("Token has expired");
        }

        // 2. Validate Issuer if configured
        String expectedIssuer = appProperties.getSupabase().getJwtIssuer();
        if (StringUtils.hasText(expectedIssuer)) {
            if (!expectedIssuer.equals(claims.getIssuer())) {
                throw new JwtValidationException("Token issuer '" + claims.getIssuer() + "' does not match expected '" + expectedIssuer + "'");
            }
        }

        // 3. Validate Audience if configured
        String expectedAudience = appProperties.getSupabase().getJwtAudience();
        if (StringUtils.hasText(expectedAudience)) {
            List<String> aud = claims.getAudience();
            if (aud == null || !aud.contains(expectedAudience)) {
                throw new JwtValidationException("Token audience '" + aud + "' does not contain required '" + expectedAudience + "'");
            }
        }

        // 4. Validate Subject (UUID)
        String sub = claims.getSubject();
        if (!StringUtils.hasText(sub)) {
            throw new JwtValidationException("Missing subject (sub) claim in token");
        }

        UUID userId;
        try {
            userId = UUID.fromString(sub);
        } catch (IllegalArgumentException e) {
            throw new JwtValidationException("Subject claim is not a valid UUID: " + sub);
        }

        // 5. Cryptographic Signature Verification
        verifySignature(signedJWT);

        // 6. Extract Email and Roles
        Object emailClaim = claims.getClaim("email");
        String email = emailClaim instanceof String s ? s : "";

        List<String> roles = new ArrayList<>();
        roles.add("USER");

        Object appMetadataObj = claims.getClaim("app_metadata");
        if (appMetadataObj instanceof Map<?, ?> meta) {
            Object roleObj = meta.get("role");
            if (roleObj instanceof String r && "admin".equalsIgnoreCase(r)) {
                roles.add("ADMIN");
            }
        }
        Object roleClaim = claims.getClaim("role");
        if (roleClaim instanceof String r && "admin".equalsIgnoreCase(r)) {
            if (!roles.contains("ADMIN")) roles.add("ADMIN");
        }

        if (roles.contains("ADMIN")) roles.remove("USER");
        return new AuthenticatedUser(userId, email, roles);
    }

    private void verifySignature(SignedJWT signedJWT) {
        String kid = signedJWT.getHeader().getKeyID();

        // Check test JWK set first if set (hermetic testing)
        if (testJwkSet != null) {
            JWK jwk = kid != null ? testJwkSet.getKeyByKeyId(kid) : testJwkSet.getKeys().stream().findFirst().orElse(null);
            if (jwk == null) {
                throw new JwtValidationException("Key ID not found in JWK set: " + kid);
            }
            if (!verifyWithJwk(signedJWT, jwk)) {
                throw new JwtValidationException("Invalid JWT signature");
            }
            return;
        }

        // Check Remote JWK Source
        if (jwkSource != null) {
            try {
                List<JWK> matches = jwkSource.get(new com.nimbusds.jose.jwk.JWKSelector(
                        new com.nimbusds.jose.jwk.JWKMatcher.Builder().keyID(kid).build()), null);
                if (matches.isEmpty()) {
                    throw new JwtValidationException("No matching key found in JWKS for kid: " + kid);
                }
                if (!verifyWithJwk(signedJWT, matches.get(0))) {
                    throw new JwtValidationException("Invalid JWT signature");
                }
                return;
            } catch (Exception e) {
                throw new JwtValidationException("Failed to verify signature against JWKS: " + e.getMessage(), e);
            }
        }

        // Fail-closed: No JWKS available
        throw new JwtValidationException("JWKS verification failed: no valid key source configured (fail-closed)");
    }

    private boolean verifyWithJwk(SignedJWT signedJWT, JWK jwk) {
        try {
            JWSVerifier verifier;
            if (jwk instanceof RSAKey rsaKey) {
                verifier = new RSASSAVerifier(rsaKey.toRSAPublicKey());
            } else if (jwk instanceof ECKey ecKey) {
                verifier = new ECDSAVerifier(ecKey.toECPublicKey());
            } else {
                throw new JwtValidationException("Unsupported key type: " + jwk.getKeyType());
            }
            return signedJWT.verify(verifier);
        } catch (Exception e) {
            throw new JwtValidationException("Verification error: " + e.getMessage(), e);
        }
    }
}
