#!/usr/bin/env bash
# Lab 8 grader — checks YOUR assert.sh harness counts correctly and lints clean.
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$HERE/../../_exercise.sh"
ex_setup lab8 "$HERE"

LIB="$TARGET/assert.sh"
# shellcheck source=/dev/null
source "$LIB"

echo "== the harness counts passes and failures =="
PASSED=0; FAILED=0
assert_eq "match"    "42" "42"
assert_eq "match2"   "ok" "ok"
assert_eq "mismatch" "1"  "2" >/dev/null     # a deliberate miss
is_eq "counted two passes" "${PASSED:-unset}" "2"
is_eq "counted one failure" "${FAILED:-unset}" "1"

echo "== a mismatch reports what went wrong =="
out="$(PASSED=0; FAILED=0; assert_eq "double 0" "0" "99")"
contains "a failure prints got/want" "$out" "got [0] want [99]"

echo "== quality =="
if command -v shellcheck >/dev/null 2>&1; then
  check "assert.sh is shellcheck-clean" shellcheck "$LIB"
else
  pass "assert.sh shellcheck-clean (shellcheck not installed — skipped)"
fi

ex_summary; exit $?
