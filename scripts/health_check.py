#!/usr/bin/env python3
"""Verify all Gulf Lands services respond on expected ports."""

import sys
import urllib.request

ENDPOINTS = [
    ("Python API", "http://localhost:8000/health/live"),
    ("Reco Service", "http://localhost:8001/health"),
    ("Analytics", "http://localhost:8002/health"),
    ("PHP API", "http://localhost/api/v1/health"),
]


def check(name: str, url: str) -> bool:
    try:
        with urllib.request.urlopen(url, timeout=5) as resp:
            return resp.status == 200
    except Exception as exc:
        print(f"FAIL  {name}: {exc}")
        return False


def main() -> int:
    ok = 0
    for name, url in ENDPOINTS:
        if check(name, url):
            print(f"OK    {name} ({url})")
            ok += 1
    print(f"\n{ok}/{len(ENDPOINTS)} services healthy")
    return 0 if ok == len(ENDPOINTS) else 1


if __name__ == "__main__":
    sys.exit(main())
