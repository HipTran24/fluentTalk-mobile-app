-- Durable, per-account daily reservation. No tokens or audio are stored.
CREATE TABLE live_voice_access (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    usage_day DATE NOT NULL,
    reserved_seconds INTEGER NOT NULL CHECK (reserved_seconds > 0),
    issued_at TIMESTAMP WITH TIME ZONE NOT NULL
);
CREATE INDEX idx_live_voice_user_day ON live_voice_access(user_id, usage_day);
DO $$
DECLARE api_role text;
BEGIN
    FOREACH api_role IN ARRAY ARRAY['anon', 'authenticated'] LOOP
        IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = api_role) THEN
            EXECUTE format('REVOKE ALL ON TABLE live_voice_access FROM %I', api_role);
        END IF;
    END LOOP;
END
$$;
