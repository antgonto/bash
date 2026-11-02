#!/usr/bin/env bash
# run.sh — stackctl's own test suite. Runs the control logic against the MOCK
# driver (no daemon needed). It proves ordering, flags and refusals — it does
# NOT prove a stack can be provisioned; tests/live-smoke.sh does that.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
# shellcheck source=assert.sh
source "$HERE/assert.sh"

export STACKCTL_DRIVER=mock
export STACKCTL_MOCK_STATE
STACKCTL_MOCK_STATE="$(mktemp -d "${TMPDIR:-/tmp}/stackctl-tests.XXXXXX")"
# shellcheck disable=SC2154
trap 'rc=$?; rm -rf "$STACKCTL_MOCK_STATE" "$ROOT/.render/test" "$ROOT/.render/prod" "$ROOT/envs/test.lock" "$ROOT/envs/prod.lock" "$ROOT/envs/t-"*.conf; exit "$rc"' EXIT INT TERM
calls() { cat "$STACKCTL_MOCK_STATE/calls.log" 2>/dev/null || true; }
reset() { rm -rf "$STACKCTL_MOCK_STATE"; mkdir -p "$STACKCTL_MOCK_STATE"; rm -rf "$ROOT/.render/test"; }
SC=(bash "$ROOT/bin/stackctl")
sc() { "${SC[@]}" "$@"; }
mkconf() {  # mkconf NAME KEY=VALUE...  → envs/t-NAME.conf (temporary)
  local name="$1"; shift; printf '%s\n' "$@" > "$ROOT/envs/t-$name.conf"
}

echo "# config is data"
reset
GOOD=('PROJECT=fraudclf-t' 'APP_DIR=app' 'IMAGE_SERVE=fraudclf-serve:m0' 'IMAGE_GATEWAY=nginx:1.27-alpine' 'HEALTH_PATH=/api/health' 'WAIT_TIMEOUT=5')
assert_status "validate test exits 0" 0 sc -e test validate
mkconf inj 'PORT=18080' "${GOOD[@]}" "HEALTH_BODY=ok; touch $STACKCTL_MOCK_STATE/pwned"
sc -e t-inj validate >/dev/null 2>&1 || true
assert_eq "a shell-looking value is not executed" "$([[ -e $STACKCTL_MOCK_STATE/pwned ]] && echo executed || echo data)" "data"
mkconf badport 'PORT=80a8' "${GOOD[@]}" 'HEALTH_BODY={"status":"ok"}'
assert_status "PORT=80a8 → 2" 2 sc -e t-badport validate
mkconf lowport 'PORT=80' "${GOOD[@]}" 'HEALTH_BODY={"status":"ok"}'
assert_status "PORT=80 (privileged) → 2" 2 sc -e t-lowport validate
mkconf nobody 'PORT=18080' "${GOOD[@]}"
assert_status "missing HEALTH_BODY → 2" 2 sc -e t-nobody validate
mkconf unknown 'PORT=18080' "${GOOD[@]}" 'HEALTH_BODY={"status":"ok"}' 'COLOUR=blue'
mkconf noapp 'PORT=18080' 'PROJECT=fraudclf-t' 'APP_DIR=nowhere' 'IMAGE_SERVE=fraudclf-serve:m0' 'IMAGE_GATEWAY=nginx:1.27-alpine' 'HEALTH_PATH=/api/health' 'HEALTH_BODY={"status":"ok"}' 'WAIT_TIMEOUT=5'
assert_status "APP_DIR without Dockerfile.course → 2" 2 sc -e t-noapp validate
mkconf badpath 'PORT=18080' 'PROJECT=fraudclf-t' 'APP_DIR=app' 'IMAGE_SERVE=fraudclf-serve:m0' 'IMAGE_GATEWAY=nginx:1.27-alpine' 'HEALTH_PATH=api/health' 'HEALTH_BODY={"status":"ok"}' 'WAIT_TIMEOUT=5'
assert_status "HEALTH_PATH without a leading slash → 2" 2 sc -e t-badpath validate
assert_status "unknown key → 2" 2 sc -e t-unknown validate
assert_status "no such environment → 2" 2 sc -e nope validate
assert_eq "validate makes no mutating call" "$(calls | grep -cE ' (up|down) ' || true)" "0"

echo "# validate → plan → apply"
reset
assert_status "plan exits 0" 0 sc -e test plan
assert_eq "plan makes no mutating call" "$(calls | grep -cE ' (up|down) ' || true)" "0"
assert_eq "plan on a fresh checkout says create" "$(sc -e test plan | grep -c 'up would: create' || true)" "1"
assert_status "up exits 0" 0 sc -e test up
assert_eq "up waits for health with the configured timeout" "$(calls | grep -c 'up -d --wait --wait-timeout 120' || true)" "1"
assert_eq "up is scoped to the project" "$(calls | grep -c '^compose fraudclf-test up ' || true)" "1"
assert_status "up again exits 0" 0 sc -e test up
assert_eq "plan after up is converged" "$(sc -e test plan | grep -c 'up would: nothing' || true)" "1"
mkconf bad2 'PORT=99999' "${GOOD[@]}" 'HEALTH_BODY={"status":"ok"}'
before="$(calls | grep -c ' up ' || true)"
assert_status "up with an invalid conf → 2" 2 sc -e t-bad2 up
assert_eq "validation precedes mutation" "$(calls | grep -c ' up ' || true)" "$before"

echo "# check"
assert_status "check with the exact body → 0" 0 env STACKCTL_MOCK_HEALTH='{"status":"ok"}' "${SC[@]}" -e test check
assert_status "check with a different body → 3" 3 env STACKCTL_MOCK_HEALTH='{"status": "ok"}' "${SC[@]}" -e test check
assert_status "check with the body plus a newline → 3" 3 env STACKCTL_MOCK_HEALTH=$'{"status":"ok"}\n' "${SC[@]}" -e test check
assert_status "check when unreachable → 1" 1 env STACKCTL_MOCK_DOWN=1 "${SC[@]}" -e test check
assert_eq "check asks the gateway for HEALTH_PATH" "$(calls | grep -c '^GET http://127.0.0.1:18080/api/health$' || true)" "4"

echo "# destroy and locks"
assert_status "destroy without confirmation → 2" 2 sc -e test destroy
assert_status "destroy confirmed for the wrong env → 2" 2 env CONFIRM_DESTROY=prod "${SC[@]}" -e test destroy
assert_eq "refused destroy made no down call" "$(calls | grep -c ' down' || true)" "0"
assert_status "destroy confirmed → 0" 0 env CONFIRM_DESTROY=test "${SC[@]}" -e test destroy
assert_eq "destroy removes volumes of this project only" "$(calls | grep -c '^compose fraudclf-test down -v$' || true)" "1"
assert_eq "nothing ever prunes" "$(calls | grep -c prune || true)" "0"
assert_eq "no global prune in the source" "$(grep -rc 'system prune' "$ROOT/bin" "$ROOT/lib" | awk -F: '{s+=$2} END{print s+0}')" "0"
( exec 9>"$ROOT/envs/test.lock"; flock 9; sleep 3 ) &
holder=$!; sleep 0.3
assert_status "up while test is locked → 1 (fails fast)" 1 sc -e test up
assert_status "prod is independent of test's lock" 0 sc -e prod validate
wait "$holder"

echo "# $PASSED passed, $FAILED failed"
(( FAILED == 0 ))
