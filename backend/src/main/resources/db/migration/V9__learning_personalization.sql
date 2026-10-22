CREATE TABLE learning_preferences (
    user_id UUID PRIMARY KEY,
    enabled BOOLEAN NOT NULL DEFAULT FALSE,
    save_voice_transcripts BOOLEAN NOT NULL DEFAULT FALSE,
    goal VARCHAR(100) NOT NULL DEFAULT 'Giao tiếp hằng ngày',
    topic_id UUID,
    voice VARCHAR(20) NOT NULL DEFAULT 'Aoede'
);
CREATE TABLE voice_learning_notes (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    transcript TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);
CREATE INDEX idx_voice_notes_user_time ON voice_learning_notes(user_id,created_at);
DO $$
DECLARE api_role text;
BEGIN
 FOREACH api_role IN ARRAY ARRAY['anon','authenticated'] LOOP
  IF EXISTS(SELECT 1 FROM pg_roles WHERE rolname=api_role) THEN
   EXECUTE format('REVOKE ALL ON TABLE learning_preferences, voice_learning_notes FROM %I',api_role);
  END IF;
 END LOOP;
END $$;
