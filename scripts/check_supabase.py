#!/usr/bin/env python3
"""Read-only database checks, or opt-in concurrency QA in a disposable schema."""
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import uuid
from run_backend import ROOT, load_environment


def java_check(env, sql, label):
    java_home = env.get('JAVA_HOME') or str(Path.home() / '.cache/english-speaking-ai/toolchains/jdk-27.0.1.jdk/Contents/Home')
    jars = sorted((Path.home() / '.m2/repository/org/postgresql/postgresql').glob('*/*.jar'))
    if not jars:
        raise SystemExit('Build backend first to download PostgreSQL driver.')
    code = '''import java.sql.*;
class CheckDb { public static void main(String[] args) throws Exception {
 DriverManager.setLoginTimeout(20);
 try (var c = DriverManager.getConnection(System.getenv("SPRING_DATASOURCE_URL"),
 System.getenv("SPRING_DATASOURCE_USERNAME"), System.getenv("SPRING_DATASOURCE_PASSWORD"));
 var s = c.createStatement()) {
 s.setQueryTimeout(30);
 ''' + sql + '''
 }
}}
'''
    with tempfile.TemporaryDirectory() as temporary:
        path = Path(temporary) / 'CheckDb.java'
        path.write_text(code)
        result = subprocess.run([str(Path(java_home) / 'bin/java'), '--class-path', str(jars[-1]), str(path)],
                                env=env, capture_output=True, text=True, timeout=60)
        if result.returncode:
            print(label + ': FAILED (database details hidden).')
            raise SystemExit(1)
        print(result.stdout.strip())


def main():
    env = load_environment()
    java_check(env, '''c.setReadOnly(true);
 String[] queries = {
 "select count(*) from auth.users",
 "select count(*) from english_app.flyway_schema_history where success and version is not null",
 "select count(*) from english_app.topics",
 "select count(*) from english_app.scenarios",
 "select count(*) from information_schema.role_table_grants where table_schema='english_app' and grantee in ('anon','authenticated')"
 };
 String[] labels = {"Auth users", "Successful migration records", "Topics", "Scenarios", "Public API table grants"};
 for (int i=0;i<queries.length;i++) { try(var rs=s.executeQuery(queries[i])) { rs.next(); System.out.println(labels[i]+": "+rs.getInt(1)); } }
''', 'Read-only Supabase check')
    if '--concurrency' not in sys.argv:
        return
    schema = 'qa_sessions_' + uuid.uuid4().hex[:12]
    env['QA_SCHEMA'] = schema
    url = re.sub(r'([?&])currentSchema=[^&]*', r'\1currentSchema=' + schema, env['SPRING_DATASOURCE_URL'])
    if 'currentSchema=' not in url:
        url += ('&' if '?' in url else '?') + 'currentSchema=' + schema
    env.update(QA_POSTGRES_URL=url, QA_POSTGRES_USERNAME=env['SPRING_DATASOURCE_USERNAME'],
               QA_POSTGRES_PASSWORD=env['SPRING_DATASOURCE_PASSWORD'])
    env['JAVA_HOME'] = env.get('JAVA_HOME') or str(Path.home() / '.cache/english-speaking-ai/toolchains/jdk-27.0.1.jdk/Contents/Home')
    try:
        result = subprocess.run([str(ROOT/'backend/mvnw'), '-f', str(ROOT/'backend/pom.xml'),
                                 '-Dtest=PostgresSessionConcurrencyTest', 'test'], cwd=ROOT, env=env)
    finally:
        # This identifier is generated above, never taken from a user or config.
        java_check(env, 's.execute("DROP SCHEMA IF EXISTS ' + schema + ' CASCADE"); System.out.println("Disposable QA schema removed.");', 'QA cleanup')
    raise SystemExit(result.returncode)

if __name__ == '__main__':
    main()
