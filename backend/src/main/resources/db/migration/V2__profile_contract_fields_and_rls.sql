-- V2__profile_contract_fields_and_rls.sql
-- Align profiles table with API_CONTRACT Profile schema and enable RLS

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS email VARCHAR(255);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS onboarded BOOLEAN NOT NULL DEFAULT false;

-- Enable Row Level Security (RLS) on user-facing tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- Note: When database connection is configured via user JWT (PostgREST / Supabase direct),
-- policies enforce that users may only access their own records.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'profiles_owner_policy'
    ) THEN
        CREATE POLICY profiles_owner_policy ON profiles
            FOR ALL
            USING (id = NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid)
            WITH CHECK (id = NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'user_settings' AND policyname = 'user_settings_owner_policy'
    ) THEN
        CREATE POLICY user_settings_owner_policy ON user_settings
            FOR ALL
            USING (user_id = NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid)
            WITH CHECK (user_id = NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid);
    END IF;
END
$$;
