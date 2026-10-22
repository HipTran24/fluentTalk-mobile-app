package com.englishspeaking.ai.profile.controller;

import com.englishspeaking.ai.profile.application.ProfileService;
import com.englishspeaking.ai.profile.dto.ProfileResponse;
import com.englishspeaking.ai.profile.dto.ProfileUpdateRequest;
import com.englishspeaking.ai.profile.dto.UserSettingsResponse;
import com.englishspeaking.ai.profile.dto.UserSettingsUpdateRequest;
import com.englishspeaking.ai.security.AuthenticatedUser;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/me")
public class MeController {

    private final ProfileService profileService;

    public MeController(ProfileService profileService) {
        this.profileService = profileService;
    }

    /**
     * GET /api/v1/me
     * Returns the authenticated learner profile.
     * Owner is strictly derived from verified Supabase JWT subject.
     */
    @GetMapping
    public ResponseEntity<ProfileResponse> getMe(@AuthenticationPrincipal AuthenticatedUser user) {
        ProfileResponse profile = profileService.getProfile(user.id(), user.email());
        return ResponseEntity.ok(profile);
    }

    /**
     * PATCH /api/v1/me
     * Updates own profile attributes.
     */
    @PatchMapping
    public ResponseEntity<ProfileResponse> patchMe(
            @AuthenticationPrincipal AuthenticatedUser user,
            @Valid @RequestBody ProfileUpdateRequest request) {
        ProfileResponse updated = profileService.updateProfile(user.id(), request);
        return ResponseEntity.ok(updated);
    }

    /**
     * GET /api/v1/me/settings
     * Returns own user settings (notifications, audio retention).
     */
    @GetMapping("/settings")
    public ResponseEntity<UserSettingsResponse> getSettings(@AuthenticationPrincipal AuthenticatedUser user) {
        UserSettingsResponse settings = profileService.getUserSettings(user.id());
        return ResponseEntity.ok(settings);
    }

    /**
     * PATCH /api/v1/me/settings
     * Updates own user settings.
     */
    @PatchMapping("/settings")
    public ResponseEntity<UserSettingsResponse> patchSettings(
            @AuthenticationPrincipal AuthenticatedUser user,
            @Valid @RequestBody UserSettingsUpdateRequest request) {
        UserSettingsResponse updated = profileService.updateUserSettings(user.id(), request);
        return ResponseEntity.ok(updated);
    }
}
