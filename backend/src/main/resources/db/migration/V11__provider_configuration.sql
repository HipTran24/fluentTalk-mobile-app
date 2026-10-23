CREATE TABLE provider_configuration (
 channel VARCHAR(10) PRIMARY KEY,
 provider VARCHAR(20) NOT NULL,
 model VARCHAR(100) NOT NULL,
 encrypted_key VARCHAR(8000) NOT NULL,
 revision BIGINT NOT NULL DEFAULT 0
);
DO $$
DECLARE api_role text;
BEGIN
 FOREACH api_role IN ARRAY ARRAY['anon','authenticated'] LOOP
  IF EXISTS(SELECT 1 FROM pg_roles WHERE rolname=api_role) THEN
   EXECUTE format('REVOKE ALL ON TABLE provider_configuration FROM %I',api_role);
  END IF;
 END LOOP;
END $$;
