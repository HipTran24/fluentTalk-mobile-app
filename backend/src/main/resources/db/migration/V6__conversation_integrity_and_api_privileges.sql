-- Conversation data is accessed through the authenticated Java API, never
-- through Supabase's public Data API. Keep this boundary explicit.
CREATE UNIQUE INDEX IF NOT EXISTS uq_session_messages_sequence
    ON session_messages(session_id, sequence_no);

DO $$
DECLARE api_role text;
BEGIN
    FOREACH api_role IN ARRAY ARRAY['anon', 'authenticated'] LOOP
        IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = api_role) THEN
            EXECUTE format('REVOKE ALL ON TABLE profiles, user_settings, sessions, session_messages, session_feedbacks, idempotency_keys, topics, scenarios FROM %I', api_role);
        END IF;
    END LOOP;
END
$$;
