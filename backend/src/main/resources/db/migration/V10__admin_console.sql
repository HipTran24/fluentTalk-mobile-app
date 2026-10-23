ALTER TABLE profiles ADD COLUMN revision BIGINT NOT NULL DEFAULT 0;
ALTER TABLE profiles ADD COLUMN suspended BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE scenarios ADD COLUMN revision BIGINT NOT NULL DEFAULT 0;
CREATE TABLE admin_audit_events (
 id UUID PRIMARY KEY,
 actor_id UUID NOT NULL,
 action VARCHAR(50) NOT NULL,
 target VARCHAR(120) NOT NULL,
 created_at TIMESTAMP WITH TIME ZONE NOT NULL
);
CREATE INDEX idx_admin_audit_created ON admin_audit_events(created_at);
CREATE INDEX idx_sessions_started ON sessions(started_at);
DO $$
DECLARE api_role text;
BEGIN
 FOREACH api_role IN ARRAY ARRAY['anon','authenticated'] LOOP
  IF EXISTS(SELECT 1 FROM pg_roles WHERE rolname=api_role) THEN
   EXECUTE format('REVOKE ALL ON TABLE admin_audit_events FROM %I',api_role);
  END IF;
 END LOOP;
END $$;
