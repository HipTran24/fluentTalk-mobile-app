#!/usr/bin/env python3
"""Run Spring with local configuration as data, without shell evaluation."""
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]

def load_environment():
    path = ROOT / 'config/backend.private.env'
    if not path.exists():
        raise SystemExit('Missing config/backend.private.env; copy the example first.')
    env = os.environ.copy()
    for number, line in enumerate(path.read_text().splitlines(), 1):
        if not line.strip() or line.lstrip().startswith('#'):
            continue
        if '=' not in line:
            raise SystemExit(f'Invalid configuration line {number}.')
        key, value = line.split('=', 1)
        if not key.replace('_', '').isalnum() or not key[0].isalpha():
            raise SystemExit(f'Invalid configuration name on line {number}.')
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        env[key] = value
    for key in ('SPRING_DATASOURCE_URL', 'SPRING_DATASOURCE_USERNAME', 'SPRING_DATASOURCE_PASSWORD',
                'SUPABASE_URL', 'SUPABASE_JWT_ISSUER', 'SUPABASE_JWKS_URL'):
        if not env.get(key) or 'DAN_' in env[key] or 'YOUR_' in env[key]:
            raise SystemExit(f'Missing configuration: {key}')
    return env

def main():
    env = load_environment()
    # Prefer explicit JAVA_HOME, otherwise the toolchain already used by this project.
    java_home = env.get('JAVA_HOME')
    if not java_home:
        candidate = Path.home() / '.cache/english-speaking-ai/toolchains/jdk-27.0.1.jdk/Contents/Home'
        if candidate.exists():
            env['JAVA_HOME'] = str(candidate)
    if '--check-config' in sys.argv:
        print('Backend configuration present. Secret values hidden.')
        print('Gemini configured:', bool(env.get('GEMINI_API_KEY') and env.get('GEMINI_MODEL')))
        print('Gemini Live configured:', bool(env.get('GEMINI_API_KEY') and env.get('GEMINI_LIVE_MODEL', 'gemini-3.8-live')))
        return
    jar = ROOT / 'backend/target/backend-0.1.0-SNAPSHOT.jar'
    if not jar.exists():
        raise SystemExit('Build first: cd backend && ./mvnw verify (Java 27 required).')
    java_binary = 'bin/java.exe' if os.name == 'nt' else 'bin/java'
    java = str(Path(env['JAVA_HOME']) / java_binary) if env.get('JAVA_HOME') else 'java'
    try:
        process = subprocess.Popen([java, '-Xmx512m', '-jar', str(jar)], cwd=ROOT, env=env)
        process.wait()
    except KeyboardInterrupt:
        process.terminate()
        process.wait(timeout=30)
    raise SystemExit(process.returncode)

if __name__ == '__main__':
    main()
