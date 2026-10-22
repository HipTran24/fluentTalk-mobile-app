#!/usr/bin/env python3
"""Inspect push-eligible files; report paths/types only, never credential values.

This is a focused local check, not a substitute for a dedicated secret scanner.
"""
import argparse
import base64
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
PATTERNS = {
    'Google API key': re.compile(r'AIza[0-9A-Za-z_-]{30,}'),
    'Private key': re.compile(r'-----BEGIN (?:RSA |EC |DSA |OPENSSH |ENCRYPTED )?PRIVATE KEY-----'),
    'Supabase secret key': re.compile(r'sb_secret_[A-Za-z0-9_-]{15,}'),
    'Supabase management token': re.compile(r'sbp_[a-f0-9]{40,}'),
    'GitHub token': re.compile(r'(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})'),
    'AWS access key': re.compile(r'(?:AKIA|ASIA)[A-Z0-9]{16}'),
}
JWT = re.compile(r'eyJ[A-Za-z0-9_-]+\.([A-Za-z0-9_-]+)\.[A-Za-z0-9_-]+')


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT, stderr=subprocess.DEVNULL)


def known_private_values():
    result = []
    path = ROOT / 'config/backend.private.env'
    if path.is_file():
        for line in path.read_text().splitlines():
            name, separator, value = line.partition('=')
            value = value.strip().strip('\"\'')
            if separator and re.search(r'(PASSWORD|API_KEY|SECRET|SERVICE_ROLE)', name) and len(value) > 7:
                if not any(marker in value for marker in ('YOUR_', 'DIEN_', 'DAN_')):
                    result.append(value)
    return result


def inspect(text, private_values):
    findings = [label for label, pattern in PATTERNS.items() if pattern.search(text)]
    if any(value in text for value in private_values):
        findings.append('Current private configuration value')
    for match in JWT.finditer(text):
        try:
            payload = match.group(1)
            claims = json.loads(base64.urlsafe_b64decode(payload + '=' * (-len(payload) % 4)))
            if claims.get('role') in ('service_role', 'authenticated'):
                findings.append('Supabase privileged/user JWT')
                break
        except (ValueError, UnicodeError, TypeError):
            continue
    return findings


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--history', action='store_true', help='Also inspect reachable commits.')
    args = parser.parse_args()
    values = known_private_values()
    paths = set(filter(None, git('ls-files', '-z', '--cached', '--others', '--exclude-standard').decode().split('\0')))
    found = False
    for name in sorted(paths):
        path = ROOT / name
        if not path.is_file() or path.is_symlink():
            continue
        try:
            findings = inspect(path.read_text(), values)
        except (UnicodeError, OSError):
            continue
        if findings:
            found = True
            print(f'{name}: {", ".join(findings)}')
    # A staged file can contain an older secret even if the working file is clean.
    staged = inspect(git('diff', '--cached', '--no-ext-diff', '--no-color').decode(errors='replace'), values)
    if staged:
        found = True
        print('Staged diff: ' + ', '.join(staged))
    if args.history:
        history = inspect(git('log', '--all', '-p', '--format=', '--no-ext-diff', '--no-color').decode(errors='replace'), values)
        if history:
            found = True
            print('Git history: ' + ', '.join(history))
    if found:
        print('Review findings before pushing. Credential values are hidden.')
        return 1
    print(f'No matching credentials in {len(paths)} push-eligible files, staged changes' +
          (' or reachable Git history.' if args.history else '.'))
    return 0


if __name__ == '__main__':
    sys.exit(main())
