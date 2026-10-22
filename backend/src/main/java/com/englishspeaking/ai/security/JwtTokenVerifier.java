package com.englishspeaking.ai.security;

public interface JwtTokenVerifier {
    /**
     * Verifies the cryptographic signature, issuer, audience, and expiration of a JWT token.
     * Returns the verified AuthenticatedUser or throws JwtValidationException.
     */
    AuthenticatedUser verify(String token);
}
