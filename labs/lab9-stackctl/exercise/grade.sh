#!/usr/bin/env bash
# Lab 9 grader — checks YOUR stackctl's control logic with the MOCK driver
# (no Docker daemon needed) and lints it. Sections: 09a config+check,
# 09b plan/up/destroy/lock, 09c runbook. A green grader is NOT provisioning
# evidence — tests/live-smoke.sh on a daemon machine is (CAP-01).
# shellcheck disable=SC2016  # the single-quoted bash -c bodies take $1 from their own argv on purpose
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$HERE/../../_exercise.sh"
ex_setup lab9 "$HERE"

export STACKCTL_DRIVER=mock
export STACKCTL_MOCK_STATE
STACKCTL_MOCK_STATE="$(mktemp -d "${TMPDIR:-/tmp}/lab9-grade.XXXXXX")"
# shellcheck disable=SC2154
trap 'rc=$?; rm -rf "$STACKCTL_MOCK_STATE" "$TARGET/.render" "$TARGET/envs/"*.lock "$TARGET/envs/g-"*.conf; exit "$rc"' EXIT INT TERM
SC=(bash "$TARGET/bin/stackctl")
calls() { cat "$STACKCTL_MOCK_STATE/calls.log" 2>/dev/null || true; }
reset() { rm -rf "$STACKCTL_MOCK_STATE" "$TARGET/.render"; mkdir -p "$STACKCTL_MOCK_STATE"; }
status_of() { "$@" >/dev/null 2>&1; echo $?; }
mkconf() { local name="$1"; shift; printf '%s\n' "$@" > "$TARGET/envs/g-$name.conf"; }
GOOD=('PROJECT=fraudclf-g' 'APP_DIR=app' 'IMAGE_SERVE=fraudclf-serve:m0' 'IMAGE_GATEWAY=nginx:1.27-alpine' 'HEALTH_PATH=/api/health' 'WAIT_TIMEOUT=7')
OKB='HEALTH_BODY={"status":"ok"}'

echo "== 09a: configuration is data =="
reset
is_eq "validate test → 0" "$(status_of "${SC[@]}" -e test validate)" "0"
mkconf inj 'PORT=18080' "${GOOD[@]}" "HEALTH_BODY=ok; touch $STACKCTL_MOCK_STATE/pwned"
"${SC[@]}" -e g-inj validate >/dev/null 2>&1 || true
check "the conf file is parsed, never executed" test ! -e "$STACKCTL_MOCK_STATE/pwned"
mkconf badport 'PORT=80a8' "${GOOD[@]}" "$OKB"
is_eq "PORT=80a8 → 2" "$(status_of "${SC[@]}" -e g-badport validate)" "2"
mkconf highport 'PORT=70000' "${GOOD[@]}" "$OKB"
is_eq "PORT=70000 → 2" "$(status_of "${SC[@]}" -e g-highport validate)" "2"
mkconf nobody 'PORT=18080' "${GOOD[@]}"
is_eq "missing HEALTH_BODY → 2" "$(status_of "${SC[@]}" -e g-nobody validate)" "2"
msg="$("${SC[@]}" -e g-nobody validate 2>&1 >/dev/null || true)"
contains "the missing key is named on stderr" "$msg" "HEALTH_BODY"
mkconf unknown 'PORT=18080' "${GOOD[@]}" "$OKB" 'COLOUR=blue'
is_eq "unknown key COLOUR → 2" "$(status_of "${SC[@]}" -e g-unknown validate)" "2"
mkconf noapp 'PORT=18080' 'PROJECT=fraudclf-g' 'APP_DIR=nowhere' 'IMAGE_SERVE=fraudclf-serve:m0' 'IMAGE_GATEWAY=nginx:1.27-alpine' 'HEALTH_PATH=/api/health' "$OKB" 'WAIT_TIMEOUT=7'
is_eq "APP_DIR without Dockerfile.course → 2" "$(status_of "${SC[@]}" -e g-noapp validate)" "2"
check "no source/eval of the conf anywhere" bash -c '! grep -nE "(^|[^a-z_])(source|eval|\.) +[\"\x27]?\\\$(CONF_FILE|file|conf)" "$1"/lib/config.sh' _ "$TARGET"
is_eq "check: exact body → 0" "$(STACKCTL_MOCK_HEALTH='{"status":"ok"}' status_of "${SC[@]}" -e test check)" "0"
is_eq "check: different body → 3" "$(STACKCTL_MOCK_HEALTH='{"status": "ok"}' status_of "${SC[@]}" -e test check)" "3"
is_eq "check: body + trailing newline → 3" "$(STACKCTL_MOCK_HEALTH=$'{"status":"ok"}\n' status_of "${SC[@]}" -e test check)" "3"
is_eq "check: unreachable → 1" "$(STACKCTL_MOCK_DOWN=1 status_of "${SC[@]}" -e test check)" "1"
is_eq "check asks the gateway for HEALTH_PATH" "$(calls | grep -c '^GET http://127.0.0.1:18080/api/health$' || true)" "4"

echo "== 09b: validate → plan → apply, converge, destroy, lock =="
reset
is_eq "plan → 0" "$(status_of "${SC[@]}" -e test plan)" "0"
is_eq "plan made no up/down call" "$(calls | grep -cE ' (up|down)( |$)' || true)" "0"
contains "plan states what up would do" "$("${SC[@]}" -e test plan 2>/dev/null)" "up would:"
is_eq "up → 0" "$(status_of "${SC[@]}" -e test up)" "0"
is_eq "up waits for health (--wait --wait-timeout 120)" "$(calls | grep -c '^compose fraudclf-test up -d --wait --wait-timeout 120$' || true)" "1"
is_eq "second up → 0" "$(status_of "${SC[@]}" -e test up)" "0"
contains "plan after up reports converged" "$("${SC[@]}" -e test plan 2>/dev/null)" "up would: nothing"
mkconf bad2 'PORT=99999' "${GOOD[@]}" "$OKB"
n_before="$(calls | grep -c ' up ' || true)"
is_eq "up with an invalid conf → 2" "$(status_of "${SC[@]}" -e g-bad2 up)" "2"
is_eq "…and made no up call (validate precedes mutation)" "$(calls | grep -c ' up ' || true)" "$n_before"
is_eq "destroy without CONFIRM_DESTROY → 2" "$(status_of "${SC[@]}" -e test destroy)" "2"
is_eq "destroy with CONFIRM_DESTROY=prod on test → 2" "$(CONFIRM_DESTROY=prod status_of "${SC[@]}" -e test destroy)" "2"
is_eq "refusals made no down call" "$(calls | grep -c ' down' || true)" "0"
is_eq "destroy with CONFIRM_DESTROY=test → 0" "$(CONFIRM_DESTROY=test status_of "${SC[@]}" -e test destroy)" "0"
is_eq "destroy is 'down -v' scoped to fraudclf-test" "$(calls | grep -c '^compose fraudclf-test down -v$' || true)" "1"
is_eq "nothing prunes (calls)" "$(calls | grep -c prune || true)" "0"
check "nothing prunes (source)" bash -c '! grep -rq "system prune" "$1/bin" "$1/lib"' _ "$TARGET"
( exec 9>"$TARGET/envs/test.lock"; flock 9; sleep 3 ) & holder=$!; sleep 0.3
is_eq "up while test is locked → 1" "$(status_of "${SC[@]}" -e test up)" "1"
wait "$holder"

echo "== 09c: handover =="
check "RUNBOOK.md has no TODO left" bash -c '! grep -q TODO "$1/RUNBOOK.md"' _ "$TARGET"
check "RUNBOOK.md keeps the six sections" bash -c 'for h in "What this stack is" Operate Diagnose Recover "Versions and digests" "Inherited findings"; do grep -q "^## .*$h" "$1/RUNBOOK.md" || exit 1; done' _ "$TARGET"

echo "== quality =="
if command -v shellcheck >/dev/null 2>&1; then
  check "stackctl is shellcheck-clean (bin + lib + tests)" shellcheck -x -P SCRIPTDIR "$TARGET/bin/stackctl" "$TARGET"/lib/*.sh "$TARGET"/tests/*.sh
else
  pass "shellcheck-clean (shellcheck not installed — skipped)"
fi

ex_summary; exit $?
