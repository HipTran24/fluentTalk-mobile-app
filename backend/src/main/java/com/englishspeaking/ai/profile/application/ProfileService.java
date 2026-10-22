package com.englishspeaking.ai.profile.application;

import com.englishspeaking.ai.common.error.ApiException;
import com.englishspeaking.ai.profile.domain.Profile;
import com.englishspeaking.ai.profile.domain.UserSettings;
import com.englishspeaking.ai.profile.dto.ProfileResponse;
import com.englishspeaking.ai.profile.dto.ProfileUpdateRequest;
import com.englishspeaking.ai.profile.dto.UserSettingsResponse;
import com.englishspeaking.ai.profile.dto.UserSettingsUpdateRequest;
import com.englishspeaking.ai.profile.infrastructure.ProfileRepository;
import com.englishspeaking.ai.profile.infrastructure.UserSettingsRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.UUID;

@Service
@Transactional
public class ProfileService {

    private final ProfileRepository profileRepository;
    private final UserSettingsRepository userSettingsRepository;

    public ProfileService(ProfileRepository profileRepository, UserSettingsRepository userSettingsRepository) {
        this.profileRepository = profileRepository;
        this.userSettingsRepository = userSettingsRepository;
    }

    public ProfileResponse getProfile(UUID userId, String emailFallback) {
        Profile profile = profileRepository.findById(userId).orElseGet(() -> {
            Profile newProfile = new Profile(userId, emailFallback, "Learner");
            return profileRepository.save(newProfile);
        });
        return ProfileResponse.from(profile);
    }

    public ProfileResponse updateProfile(UUID userId, ProfileUpdateRequest request) {
        Profile profile = profileRepository.findById(userId).orElseGet(() -> new Profile(userId, null, "Learner"));

        if (StringUtils.hasText(request.displayName())) {
            profile.setDisplayName(request.displayName().trim());
        }
        if (StringUtils.hasText(request.level())) {
            profile.setLevel(request.level().trim());
        }
        if (request.goal() != null) {
            profile.setGoal(request.goal().trim());
        }
        if (request.dailyMinutes() != null) {
            if (request.dailyMinutes() < 5 || request.dailyMinutes() > 60) {
                throw new ApiException("VALIDATION_FAILED", "dailyMinutes must be between 5 and 60", HttpStatus.BAD_REQUEST);
            }
            profile.setDailyMinutes(request.dailyMinutes());
        }
        if (request.onboarded() != null) {
            profile.setOnboarded(request.onboarded());
        }

        Profile saved = profileRepository.save(profile);
        return ProfileResponse.from(saved);
    }

    public UserSettingsResponse getUserSettings(UUID userId) {
        UserSettings settings = userSettingsRepository.findById(userId).orElseGet(() -> {
            UserSettings newSettings = new UserSettings(userId);
            return userSettingsRepository.save(newSettings);
        });
        return UserSettingsResponse.from(settings);
    }

    public UserSettingsResponse updateUserSettings(UUID userId, UserSettingsUpdateRequest request) {
        UserSettings settings = userSettingsRepository.findById(userId).orElseGet(() -> new UserSettings(userId));

        if (request.notificationsEnabled() != null) {
            settings.setNotificationsEnabled(request.notificationsEnabled());
        }
        if (request.audioRetentionDays() != null) {
            if (request.audioRetentionDays() < 0) {
                throw new ApiException("VALIDATION_FAILED", "audioRetentionDays must be >= 0", HttpStatus.BAD_REQUEST);
            }
            settings.setAudioRetentionDays(request.audioRetentionDays());
        }

        UserSettings saved = userSettingsRepository.save(settings);
        return UserSettingsResponse.from(saved);
    }
}
