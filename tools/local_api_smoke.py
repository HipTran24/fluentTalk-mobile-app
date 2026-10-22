#!/usr/bin/env python3
"""Exercise a packaged backend with local RSA fixtures and real PostgreSQL.

No cloud identity/provider acceptance is implied. The database must be a
disposable local development database. Private keys/tokens are never printed.
"""
import argparse
import base64
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import threading
import time
from urllib.error import HTTPError, URLError
from urllib.request import Request, build_opener
import uuid

from benchmark_api import NoRedirect


def b64(value):
    return base64.urlsafe_b64encode(value).decode().rstrip('=')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--jar', default='backend/target/backend-0.1.0-SNAPSHOT.jar')
    parser.add_argument('--database', default='esp_final')
    parser.add_argument('--output', default='docs/qa/local-api-smoke.json')
    args = parser.parse_args()
    if not args.database.replace('_', '').isalnum():
        parser.error('Use a local development database name')
    cache = Path.home() / '.cache/english-speaking-ai'
    java_home = cache / 'toolchains/jdk-27.0.1.jdk/Contents/Home'
    db = dict(line.split('=', 1) for line in
              (cache / 'local-postgres.env').read_text().splitlines())
    checks = []
    issuer = 'https://local-fixture.test/auth/v1'
    server = process = None
    with tempfile.TemporaryDirectory(prefix='esp-smoke-') as directory:
        temp = Path(directory)
        key = temp / 'signing.pem'
        subprocess.run(['openssl', 'genpkey', '-algorithm', 'RSA', '-pkeyopt',
                        'rsa_keygen_bits:2048', '-out', str(key)], check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        key.chmod(0o600)
        modulus = subprocess.check_output(
            ['openssl', 'rsa', '-in', str(key), '-noout', '-modulus'],
            stderr=subprocess.DEVNULL).decode().strip().split('=', 1)[1]
        public = json.dumps({'keys': [{'kty': 'RSA', 'kid': 'local-qa',
                    'use': 'sig', 'alg': 'RS256',
                    'n': b64(bytes.fromhex(modulus)), 'e': 'AQAB'}]}).encode()

        class JwksHandler(BaseHTTPRequestHandler):
            def do_GET(self):
                if self.path != '/jwks':
                    self.send_error(404)
                    return
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(public)

            def log_message(self, *unused):
                pass

        server = ThreadingHTTPServer(('127.0.0.1', 0), JwksHandler)
        threading.Thread(target=server.serve_forever, daemon=True).start()
        jar = temp / 'backend.jar'
        shutil.copyfile(args.jar, jar)
        env = os.environ.copy()
        env.update(PORT='18081', SERVER_ADDRESS='127.0.0.1',
            SPRING_DATASOURCE_URL=f'jdbc:postgresql://127.0.0.1:55432/{args.database}',
            SPRING_DATASOURCE_USERNAME=db['POSTGRES_USER'],
            SPRING_DATASOURCE_PASSWORD=db['POSTGRES_PASSWORD'],
            SUPABASE_JWT_ISSUER=issuer, SUPABASE_JWT_AUDIENCE='authenticated',
            SUPABASE_JWKS_URL=f'http://127.0.0.1:{server.server_port}/jwks')
        log = (cache / 'final-api-runtime.log').open('w')
        try:
            process = subprocess.Popen([str(java_home / 'bin/java'), '-jar', str(jar)],
                                       env=env, stdout=log, stderr=subprocess.STDOUT)
            opener = build_opener(NoRedirect)

            def request(path, token=None, data=None):
                headers = {'Content-Type': 'application/json'}
                if token:
                    headers['Authorization'] = 'Bearer ' + token
                method = 'PATCH' if data is not None else 'GET'
                req = Request('http://127.0.0.1:18081/api/v1/' + path,
                    headers=headers, method=method,
                    data=json.dumps(data).encode() if data is not None else None)
                try:
                    with opener.open(req, timeout=5) as response:
                        return response.status, json.loads(response.read())
                except HTTPError as error:
                    with error:
                        return error.code, json.loads(error.read())

            def token(subject, **changes):
                claims = dict(sub=subject, email='fixture@example.test',
                    iss=issuer, aud='authenticated', exp=int(time.time()) + 300,
                    app_metadata={'role': 'authenticated'})
                claims.update(changes)
                text = b64(json.dumps({'alg': 'RS256', 'kid': 'local-qa'}).encode())
                text += '.' + b64(json.dumps(claims).encode())
                signature = subprocess.run(['openssl', 'dgst', '-sha256', '-sign',
                    str(key)], input=text.encode(), stdout=subprocess.PIPE,
                    stderr=subprocess.DEVNULL, check=True).stdout
                return text + '.' + b64(signature)

            def check(name, condition):
                checks.append({'name': name, 'passed': bool(condition)})

            for _ in range(60):
                try:
                    if request('health')[0] == 200:
                        break
                except (URLError, OSError):
                    time.sleep(.5)
            check('health matches exact schema', request('health') == (200, {'status': 'UP'}))
            first, second = str(uuid.uuid4()), str(uuid.uuid4())
            a, b = token(first), token(second)
            check('anonymous profile denied', request('me')[0] == 401)
            for name, changes in [
                ('expired token', {'exp': int(time.time()) - 60}),
                ('wrong issuer', {'iss': 'https://wrong.test'}),
                ('wrong audience', {'aud': 'other'}),
            ]:
                check(name + ' denied', request('me', token(first, **changes))[0] == 401)
            check('tampered signature denied', request('me', a[:-8] + 'AAAAAAAA')[0] == 401)
            check('profile A saves', request('me', a, {'displayName': 'Local QA A'})[0] == 200)
            check('profile B saves', request('me', b, {'displayName': 'Local QA B'})[0] == 200)
            check('profile A isolated', request('me', a)[1].get('displayName') == 'Local QA A')
            check('profile B isolated', request('me', b)[1].get('displayName') == 'Local QA B')
            check('user-controlled admin metadata denied', request('admin/status',
                token(first, user_metadata={'role': 'admin'}))[0] == 403)
            check('verified admin claim allowed', request('admin/status',
                token(first, app_metadata={'role': 'admin'}))[0] == 200)
            status, topics = request('topics', a)
            check('four topics', status == 200 and isinstance(topics, list) and len(topics) == 4)
            status, page = request('scenarios?page=0&size=3', a)
            check('catalog page matches contract', status == 200 and
                set(page) == {'items', 'page', 'size', 'hasMore'} and len(page.get('items', [])) == 3)
            report = dict(timestampUtc=datetime.now(timezone.utc).isoformat(),
                identitySource='locally signed RSA fixtures and local JWKS; not Supabase cloud',
                database='fresh migrated PostgreSQL17 local development database',
                checks=checks, passed=sum(c['passed'] for c in checks),
                total=len(checks), allPassed=all(c['passed'] for c in checks))
            Path(args.output).write_text(json.dumps(report, indent=2) + '\n')
            print(json.dumps(report, indent=2))
            return 0 if report['allPassed'] else 1
        finally:
            if process:
                process.terminate()
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
            log.close()
            if server:
                server.shutdown()
                server.server_close()


if __name__ == '__main__':
    raise SystemExit(main())
