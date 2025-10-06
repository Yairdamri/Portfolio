#!/usr/bin/env python3
import argparse
import json
import os
import random
import string
import subprocess
import sys
import time
import urllib.request
import urllib.error
from typing import Tuple, Optional, Dict


def sh(cmd: str, cwd: Optional[str] = None, check: bool = True) -> Tuple[int, str, str]:
    proc = subprocess.Popen(cmd, cwd=cwd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    out, err = proc.communicate()
    if check and proc.returncode != 0:
        print(out)
        print(err, file=sys.stderr)
        raise SystemExit(proc.returncode)
    return proc.returncode, out, err


def http_json(method: str, url: str, data: Optional[dict] = None, headers: Optional[Dict[str, str]] = None) -> Tuple[int, dict, str]:
    req_headers = headers.copy() if headers else {}
    body_bytes = None
    if data is not None:
        body_bytes = json.dumps(data).encode("utf-8")
        req_headers['Content-Type'] = 'application/json'
    req = urllib.request.Request(url=url, data=body_bytes, method=method, headers=req_headers)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            status = resp.getcode()
            raw = resp.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        status = e.code
        raw = e.read().decode("utf-8", errors="replace")
    except urllib.error.URLError as e:
        raise RuntimeError(f"HTTP error for {method} {url}: {e}")

    try:
        parsed = json.loads(raw) if raw else {}
    except json.JSONDecodeError:
        parsed = {}
    return status, parsed, raw


def wait_for_health(base: str, timeout_sec: int = 120) -> None:
    deadline = time.time() + timeout_sec
    url = f"{base.rstrip('/')}/health"
    print(f"Waiting for health at {url} (timeout {timeout_sec}s)...")
    last_err = None
    while time.time() < deadline:
        try:
            code, _, _ = http_json("GET", url)
            if code == 200:
                print("Health OK")
                return
        except Exception as e:
            last_err = e
        time.sleep(2)
    raise RuntimeError(f"Service did not become healthy in {timeout_sec}s. Last error: {last_err}")


def random_email() -> str:
    ts = int(time.time())
    suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))
    return f"ci+{ts}-{suffix}@example.com"


def ensure_auth_token(base: str, email: Optional[str] = None, password: str = "pass1234") -> str:
    email = email or random_email()
    name = "CI Runner"
    # Try register
    code, parsed, raw = http_json("POST", f"{base}/v1/auth/register", {"email": email, "password": password, "name": name})
    if code == 201:
        token = parsed.get("token")
        if not token:
            raise RuntimeError(f"Register 201 but no token in body: {raw}")
        return token
    # If conflict or other, try login
    code, parsed, raw = http_json("POST", f"{base}/v1/auth/login", {"email": email, "password": password})
    if code != 200:
        raise RuntimeError(f"Auth failed. HTTP {code}. Body: {raw}")
    token = parsed.get("token")
    if not token:
        raise RuntimeError(f"Login 200 but no token in body: {raw}")
    return token


def run_api_flow(base: str) -> None:
    token = ensure_auth_token(base)
    auth = {"Authorization": f"Bearer {token}"}

    # 1) Exercises list (GET)
    code, parsed, raw = http_json("GET", f"{base}/v1/exercises", headers=auth)
    assert code == 200, f"/v1/exercises expected 200 got {code} body={raw}"
    assert "items" in parsed and isinstance(parsed.get("count"), int), "Invalid exercises response"

    # 2) Create plan (POST)
    code, parsed, raw = http_json("POST", f"{base}/v1/plans", data={"days_per_week": 3, "weeks": 1}, headers=auth)
    assert code == 201, f"Create plan expected 201 got {code} body={raw}"
    plan_id = parsed.get("id")
    assert plan_id, f"No plan id in response: {raw}"

    # 3) List plans (GET)
    code, parsed, raw = http_json("GET", f"{base}/v1/plans", headers=auth)
    assert code == 200, f"List plans expected 200 got {code} body={raw}"
    assert isinstance(parsed.get("items"), list), "/v1/plans did not return a list"

    # 4) Get plan by id (GET)
    code, parsed, raw = http_json("GET", f"{base}/v1/plans/{plan_id}", headers=auth)
    assert code == 200, f"Get plan expected 200 got {code} body={raw}"

    # 5) Complete a workout (POST)
    payload = {
        "plan_id": plan_id,
        "session_index": 0,
        "duration_minutes": 30,
        "logged_exercises": [
            {"exercise_id": "push_up", "sets": [{"reps": 10, "weight": 0}]}
        ],
    }
    code, parsed, raw = http_json("POST", f"{base}/v1/workouts/complete", data=payload, headers=auth)
    assert code == 201, f"Complete workout expected 201 got {code} body={raw}"
    completion_id = parsed.get("id")
    assert completion_id, f"Completion response missing id: {raw}"

    # 6) Weekly summary (GET)
    code, parsed, raw = http_json("GET", f"{base}/v1/workouts/summary", headers=auth)
    assert code == 200, f"Weekly summary expected 200 got {code} body={raw}"

    # 7) History (GET)
    code, parsed, raw = http_json("GET", f"{base}/v1/workouts/history?limit=10", headers=auth)
    assert code == 200, f"History expected 200 got {code} body={raw}"
    ids_before = [it.get("completion", {}).get("id") for it in (parsed.get("items") or [])]
    assert completion_id in ids_before, "New completion not found in history"

    # 8) Delete the completion (DELETE)
    code, _, _ = http_json("DELETE", f"{base}/v1/workouts/{completion_id}", headers=auth)
    assert code == 204, f"Delete completion expected 204 got {code}"

    # 9) History should no longer include the deleted completion
    code, parsed, raw = http_json("GET", f"{base}/v1/workouts/history?limit=10", headers=auth)
    assert code == 200, f"History after delete expected 200 got {code} body={raw}"
    ids_after = [it.get("completion", {}).get("id") for it in (parsed.get("items") or [])]
    assert completion_id not in ids_after, "Deleted completion still present in history"

    # Optional: method not allowed check (DELETE nonexistent)
    code, _, _ = http_json("DELETE", f"{base}/v1/plans/{plan_id}", headers=auth)
    assert code in (404, 405), f"Unexpected code for DELETE /v1/plans/{{id}}: {code}"


def main():
    parser = argparse.ArgumentParser(description="Python integration tests for Workout app")
    parser.add_argument('--compose-file', default='docker-compose.yaml', help='Path to docker-compose file')
    parser.add_argument('--base', default='http://localhost', help='Base URL (use http://localhost to go via nginx reverse proxy)')
    parser.add_argument('--project-dir', default='.', help='Directory containing the compose file')
    parser.add_argument('--skip-build', action='suppress', help=argparse.SUPPRESS)  # kept simple per requirements
    args = parser.parse_args()

    project_dir = os.path.abspath(args.project_dir)
    compose_path = os.path.join(project_dir, args.compose_file)
    skip_compose = os.getenv("SKIP_COMPOSE") == "1"

    try:
        # Bring up environment unless skipped (e.g., CI handles compose externally)
        if not skip_compose:
            print("Bringing up compose stack...")
            sh(f'docker compose -f "{compose_path}" up -d --build', cwd=project_dir)

        # Wait for readiness via reverse proxy
        wait_for_health(args.base, timeout_sec=180)

        # Run API flow
        run_api_flow(args.base)
        print("Integration tests OK")
    finally:
        # Clean up regardless of success/failure (only if we brought it up)
        if not skip_compose:
            print("Tearing down compose stack...")
            sh(f'docker compose -f "{compose_path}" down -v --remove-orphans || true', cwd=project_dir, check=False)


if __name__ == '__main__':
    main()
