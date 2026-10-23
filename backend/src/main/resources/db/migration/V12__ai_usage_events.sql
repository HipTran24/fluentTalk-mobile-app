CREATE TABLE ai_usage_events (
 id UUID PRIMARY KEY,
 created_at TIMESTAMP WITH TIME ZONE NOT NULL,
 usage_day DATE NOT NULL,
 provider VARCHAR(20) NOT NULL,
 model VARCHAR(100) NOT NULL,
 purpose VARCHAR(10) NOT NULL,
 outcome VARCHAR(10) NOT NULL,
 http_status INTEGER,
 duration_ms BIGINT NOT NULL,
 input_tokens BIGINT, output_tokens BIGINT, total_tokens BIGINT, cached_tokens BIGINT, reasoning_tokens BIGINT
);
CREATE INDEX idx_ai_usage_day_provider ON ai_usage_events(usage_day,provider);
DO $$
DECLARE api_role text;
BEGIN
 FOREACH api_role IN ARRAY ARRAY['anon','authenticated'] LOOP
  IF EXISTS(SELECT 1 FROM pg_roles WHERE rolname=api_role) THEN
   EXECUTE format('REVOKE ALL ON TABLE ai_usage_events FROM %I',api_role);
  END IF;
 END LOOP;
END $$;
