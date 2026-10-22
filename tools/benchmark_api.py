#!/usr/bin/env python3
"""Bounded GET benchmark. Keep provider latency and authenticated UAT separate.

Example: python3 tools/benchmark_api.py --base-url http://127.0.0.1:18080/api/v1
For an owned protected endpoint set API_BENCH_TOKEN in the environment; never
place tokens in command arguments or URLs. Output contains no response bodies.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import json
import math
import os
import platform
import time
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse
from urllib.request import HTTPRedirectHandler, Request, build_opener


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base-url', default='http://127.0.0.1:18080/api/v1')
    parser.add_argument('--path', default='health')
    parser.add_argument('--requests', type=int, default=100)
    parser.add_argument('--concurrency', type=int, default=4)
    parser.add_argument('--output')
    args = parser.parse_args()
    url = urlparse(args.base_url)
    local = url.hostname in {'localhost', '127.0.0.1', '::1', '10.0.2.2'}
    if (url.scheme not in {'http', 'https'} or not url.hostname or
            url.username or url.password or url.query or url.fragment or
            (url.scheme == 'http' and not local)):
        parser.error('Use HTTPS or explicit loopback HTTP without credentials/query')
    if (not 1 <= args.requests <= 10000 or
            not 1 <= args.concurrency <= 32):
        parser.error('requests must be 1..10000 and concurrency 1..32')
    if any(part in args.path for part in [':', '..', '?', '#', '\\', '%']):
        parser.error('Use a relative path without query or escaping')
    endpoint = args.base_url.rstrip('/') + '/' + args.path.lstrip('/')
    token = os.environ.get('API_BENCH_TOKEN')
    headers = {'Accept': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token

    def request(_):
        start = time.perf_counter()
        try:
            with build_opener(NoRedirect).open(
                    Request(endpoint, headers=headers), timeout=10) as response:
                # Bound read size so an unexpectedly large response is not an
                # unbounded memory allocation in the benchmark client.
                response.read(1024 * 1024)
                status = str(response.status)
        except HTTPError as error:
            status = str(error.code)
            error.close()
        except (URLError, TimeoutError, OSError):
            status = 'transportError'
        return (time.perf_counter() - start) * 1000, status

    warmup = [request(i) for i in range(5)]
    start = time.perf_counter()
    with ThreadPoolExecutor(max_workers=args.concurrency) as pool:
        results = list(pool.map(request, range(args.requests)))
    elapsed = time.perf_counter() - start
    successes = sorted(ms for ms, status in results if status.startswith('2'))
    statuses = {}
    for _, status in results:
        statuses[status] = statuses.get(status, 0) + 1

    def percentile(p):
        return (round(successes[max(0, math.ceil(len(successes) * p) - 1)], 2)
                if successes else None)

    report = {
        'timestampUtc': datetime.now(timezone.utc).isoformat(),
        'endpointPath': url.path.rstrip('/') + '/' + args.path.lstrip('/'),
        'scope': 'single endpoint only; excludes AI/audio/provider UAT',
        'python': platform.python_version(),
        'machine': platform.machine(),
        'requests': args.requests,
        'concurrency': args.concurrency,
        'warmupRequests': len(warmup),
        'warmupStatuses': [status for _, status in warmup],
        'statuses': statuses,
        'elapsedSeconds': round(elapsed, 3),
        'successfulLatencyMs': {'p50': percentile(.5), 'p95': percentile(.95),
                                'max': round(max(successes), 2) if successes else None},
        'allSucceeded': len(successes) == args.requests,
    }
    rendered = json.dumps(report, indent=2)
    if args.output:
        from pathlib import Path
        Path(args.output).write_text(rendered + '\n')
    print(rendered)
    return 0 if report['allSucceeded'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
