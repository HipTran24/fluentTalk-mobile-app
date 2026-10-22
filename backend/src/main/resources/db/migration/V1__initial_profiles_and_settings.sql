-- V1__initial_profiles_and_settings.sql
-- Initial Flyway migration for learner profiles and user settings
-- Corresponds to Master Plan Section 5 & Appendix C2

CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY,
    display_name VARCHAR(100),
    level VARCHAR(20) NOT NULL DEFAULT 'A1',
    goal VARCHAR(100),
    daily_minutes INT NOT NULL DEFAULT 15,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_profiles_level CHECK (level IN ('A0', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2')),
    CONSTRAINT chk_profiles_daily_minutes CHECK (daily_minutes >= 0)
);

CREATE TABLE IF NOT EXISTS user_settings (
    user_id UUID PRIMARY KEY,
    notifications_enabled BOOLEAN NOT NULL DEFAULT true,
    audio_retention_days INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_settings_profile FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
    CONSTRAINT chk_audio_retention_days CHECK (audio_retention_days >= 0)
);

CREATE INDEX IF NOT EXISTS idx_profiles_level ON profiles(level);
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON profiles(created_at DESC);
