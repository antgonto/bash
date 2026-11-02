#!/usr/bin/env bash
# Lab 8 — Testing and quality: a tiny test harness, unit tests for functions,
# black-box tests for exit codes, shellcheck as a gate, and set -x for
# debugging. Project milestone: logsleuth ships a green test suite and passes
# a zero-finding lint gate.
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/../_lib.sh"
W="$(lab_workdir lab8)"; cd "$W" || exit 1; make_fixtures "$W/fx"

echo "== a test is an assertion about an observable result =="
# the smallest harness: compare got vs want, count passes/failures. (Distinct
# variable names — dP/dF — so the demo doesn't clobber the lab's own counters.)
cat > demo_assert.sh <<'EOF'
# shellcheck shell=bash
dP=0; dF=0
assert_eq() { if [[ "$2" == "$3" ]]; then (( ++dP )); else (( ++dF )); echo "FAIL $1: got '$2' want '$3'"; fi; }
EOF
# shellcheck source=/dev/null
source ./demo_assert.sh
double() { echo $(( $1 * 2 )); }
assert_eq "double 21" "$(double 21)" "42"
is_eq "the harness counted one pass" "$dP" "1"
assert_eq "double 0 (deliberately wrong expectation)" "$(double 0)" "99" >/dev/null
is_eq "the harness counted one fail" "$dF" "1"

echo "== test the PURE functions directly (fast, precise) =="
export TOP_N=10 BRUTE_THRESHOLD=10
# shellcheck source=/dev/null
source "$COURSE_ROOT/logsleuth/lib/util.sh"
# shellcheck source=/dev/null
source "$COURSE_ROOT/logsleuth/lib/parse.sh"
is_eq "unit: field_status counts 500s"   "$(field_status "$W/fx/access.log" | grep -c '^500$')" "5"
is_eq "unit: accepted_login_count"       "$(accepted_login_count "$W/fx/auth.log")" "2"

echo "== test the CLI as a black box (exit codes are the contract) =="
is_eq "cli: version"             "$(logsleuth -V)" "logsleuth 1.0.0"
check "cli: unknown command -> 2" bash -c 'logsleuth nope 2>/dev/null; [ $? -eq 2 ]'
check "cli: good run -> 0"        bash -c 'logsleuth summary "$1" >/dev/null' _ "$W/fx/access.log"

echo "== fixtures make tests deterministic =="
# the same generator the suite uses -> identical numbers every run
is_eq "fixture access.log is always 140 lines" "$(wc -l < "$W/fx/access.log")" "140"

echo "== set -x shows every command as it runs (the debugger you already have) =="
# capture a child shell's trace (stderr) while discarding its stdout
trace="$(bash -c 'set -x; n=5; echo "$n"' 2>&1 1>/dev/null)"
contains "set -x prefixes each command with +" "$trace" "+ n=5"
contains "set -x shows the expanded echo" "$trace" "+ echo 5"

echo "== the project: its real suite is green and it passes the shellcheck gate =="
out="$(bash "$COURSE_ROOT/logsleuth/tests/run.sh")"
contains "the test suite reports 0 failed" "$out" "0 failed"
# the number of 'ok -' lines equals the passed count it reports
oks="$(grep -c '^ok - ' <<< "$out")"
passed="$(sed -n 's/^# \([0-9]*\) passed.*/\1/p' <<< "$out")"
is_eq "every reported pass is a real 'ok' line" "$oks" "$passed"
check "the test suite exits 0" bash -c 'bash "$1/logsleuth/tests/run.sh" >/dev/null' _ "$COURSE_ROOT"
check "shellcheck gate: whole project, zero findings" bash -c '
  shellcheck -x -P SCRIPTDIR "$1"/logsleuth/bin/logsleuth "$1"/logsleuth/lib/*.sh "$1"/logsleuth/tests/*.sh' _ "$COURSE_ROOT"

summary lab8
