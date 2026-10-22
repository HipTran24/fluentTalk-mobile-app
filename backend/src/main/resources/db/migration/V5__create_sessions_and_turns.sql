-- V5__create_sessions_and_turns.sql
-- Flyway migration for sessions, turns, assessments, and idempotency tracking

CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    scenario_id UUID REFERENCES scenarios(id) ON DELETE SET NULL,
    mode VARCHAR(32) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'active',
    level VARCHAR(10),
    started_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMPTZ,
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_user_created ON sessions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sessions_user_started ON sessions(user_id, started_at DESC, id DESC);
CREATE INDEX IF NOT EXISTS idx_sessions_user_mode_started ON sessions(user_id, mode, started_at DESC, id DESC);

CREATE TABLE IF NOT EXISTS session_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    role VARCHAR(16) NOT NULL,
    text TEXT NOT NULL,
    audio_url TEXT,
    sequence_no INTEGER NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    useful_phrases TEXT,
    suggested_follow_ups TEXT
);

CREATE INDEX IF NOT EXISTS idx_session_messages_session ON session_messages(session_id, sequence_no ASC);

CREATE TABLE IF NOT EXISTS session_feedbacks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE UNIQUE,
    user_id UUID NOT NULL,
    rubric_version VARCHAR(32) NOT NULL DEFAULT 'v1.1',
    status VARCHAR(32) NOT NULL DEFAULT 'ready',
    summary_vi TEXT NOT NULL,
    dimensions TEXT NOT NULL,
    overall_band DOUBLE PRECISION,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_feedbacks_user_session ON session_feedbacks(user_id, session_id);

CREATE TABLE IF NOT EXISTS idempotency_keys (
    user_id UUID NOT NULL,
    idempotency_key VARCHAR(128) NOT NULL,
    method VARCHAR(16) NOT NULL,
    resource_path VARCHAR(255) NOT NULL,
    request_hash VARCHAR(64) NOT NULL,
    response_status INTEGER NOT NULL,
    response_body TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, idempotency_key)
);

-- Row Level Security
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_feedbacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE idempotency_keys ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'sessions' AND policyname = 'sessions_owner_policy'
    ) THEN
        CREATE POLICY sessions_owner_policy ON sessions
            FOR ALL
            USING (user_id = NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid)
            WITH CHECK (user_id = NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'session_feedbacks' AND policyname = 'session_feedbacks_owner_policy'
    ) THEN
        CREATE POLICY session_feedbacks_owner_policy ON session_feedbacks
            FOR ALL
            USING (user_id = NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid)
            WITH CHECK (user_id = NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid);
    END IF;
END
$$;
