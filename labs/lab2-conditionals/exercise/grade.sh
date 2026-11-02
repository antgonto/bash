#!/usr/bin/env bash
# Lab 2 grader — checks YOUR router.sh (work/ copy, or GRADE_TARGET for CI).
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$HERE/../../_exercise.sh"
ex_setup lab2 "$HERE"

# shellcheck source=/dev/null
source "$TARGET/router.sh"

good="$(mktemp)"; printf 'x\n' > "$good"
missing="/nonexistent-xyz-$$.log"

echo "== validate_log: guard before reading =="
check  "a readable file validates (returns 0)" validate_log "$good"
denies "a missing file fails (non-zero)"        validate_log "$missing"
msg="$(validate_log "$missing" 2>&1 >/dev/null)"
contains "a missing file prints a clear message" "$msg" "cannot read log file"

echo "== route: case dispatch =="
is_eq "summary -> valid"              "$(route summary)"    "valid"
is_eq "errors  -> valid"              "$(route errors)"     "valid"
is_eq "bruteforce -> brute (prefix)"  "$(route bruteforce)" "brute"
is_eq "frobnicate -> unknown"         "$(route frobnicate)" "unknown"

rm -f "$good"
ex_summary; exit $?
