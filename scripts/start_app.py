#!/usr/bin/env python3
"""Build current sources and serve the local web app against Supabase-backed Java."""
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import time
import urllib.request
from run_backend import ROOT, load_environment


def free_port(port):
    with socket.socket() as sock:
        return sock.connect_ex(('127.0.0.1', port)) != 0


def main():
    env = load_environment()
    for port in (8080, 3000):
        if not free_port(port):
            raise SystemExit(f'Port {port} is already in use. Stop that process before starting this launcher.')
    if not env.get('CORS_ALLOWED_ORIGINS'):
        env['CORS_ALLOWED_ORIGINS'] = 'http://localhost:3000,http://127.0.0.1:3000'
    if not env.get('JAVA_HOME'):
        candidate = Path.home() / '.cache/english-speaking-ai/toolchains/jdk-27.0.1.jdk/Contents/Home'
        if candidate.exists():
            env['JAVA_HOME'] = str(candidate)
    public_path = ROOT / 'config/mobile.public.json'
    if not public_path.exists():
        raise SystemExit('Missing config/mobile.public.json.')
    public = json.loads(public_path.read_text())
    # Whitelist public configuration; never pass the backend env file to Flutter.
    web = {name: public[name] for name in ('SUPABASE_URL', 'SUPABASE_ANON_KEY')}
    web.update(API_BASE_URL='http://localhost:8080/api/v1', DEMO_MODE=False, ALLOW_INSECURE_LOCALHOST=True)
    web_path = ROOT / 'config/mobile.web.public.json'
    web_path.write_text(json.dumps(web, indent=2) + '\n')
    print('Building backend and web from current sources...', flush=True)
    build_env = {key: value for key, value in os.environ.items()
                 if not key.startswith(('SPRING_', 'SUPABASE_', 'GEMINI_'))
                 and key not in ('PORT', 'CORS_ALLOWED_ORIGINS')}
    if env.get('JAVA_HOME'):
        build_env['JAVA_HOME'] = env['JAVA_HOME']
    subprocess.run([str(ROOT / 'backend/mvnw'), '-f', str(ROOT / 'backend/pom.xml'), 'verify'], cwd=ROOT, env=build_env, check=True)
    subprocess.run(['flutter', 'build', 'web', '--no-web-resources-cdn',
                    '--dart-define-from-file=' + str(web_path)], cwd=ROOT, check=True)
    children = []
    log_dir = ROOT / '.run'
    log_dir.mkdir(exist_ok=True)
    try:
        java = str(Path(env['JAVA_HOME']) / 'bin/java') if env.get('JAVA_HOME') else 'java'
        with (log_dir / 'backend.log').open('w') as backend_log, (log_dir / 'web.log').open('w') as web_log:
            (log_dir / 'backend.log').chmod(0o600)
            process = subprocess.Popen([java, '-Xmx512m', '-jar', str(ROOT / 'backend/target/backend-0.1.0-SNAPSHOT.jar')],
                                       cwd=ROOT, env=env, stdout=backend_log, stderr=subprocess.STDOUT)
            children.append(process)
            for _ in range(90):
                if process.poll() is not None:
                    raise SystemExit('Backend failed to start. See .run/backend.log.')
                try:
                    with urllib.request.urlopen('http://localhost:8080/api/v1/health', timeout=2) as response:
                        if response.status == 200 and json.load(response).get('status') == 'UP':
                            break
                except (OSError, ValueError):
                    pass
                time.sleep(1)
            else:
                raise SystemExit('Backend readiness timed out. See .run/backend.log.')
            server = subprocess.Popen([sys.executable, str(ROOT / 'tools/serve_web.py'), str(ROOT / 'build/web')],
                                      cwd=ROOT, stdout=web_log, stderr=subprocess.STDOUT)
            children.append(server)
            time.sleep(1)
            if server.poll() is not None:
                raise SystemExit('Web server failed. See .run/web.log.')
            print('Open http://localhost:3000 — Ctrl+C stops both services.', flush=True)
            while all(child.poll() is None for child in children):
                time.sleep(1)
    except KeyboardInterrupt:
        pass
    finally:
        for child in reversed(children):
            if child.poll() is None:
                child.terminate()
        for child in children:
            try:
                child.wait(timeout=20)
            except subprocess.TimeoutExpired:
                child.kill()

if __name__ == '__main__':
    main()
