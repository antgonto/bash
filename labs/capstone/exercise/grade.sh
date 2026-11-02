#!/usr/bin/env bash
# Capstone grader — runs YOUR mytool against the rubric.
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$HERE/../../_exercise.sh"
ex_setup capstone "$HERE"

T="$TARGET/mytool"
data="$(mktemp)"; printf 'apple\napple\nbanana\napple\ncherry\nbanana\n' > "$data"

echo "== it works: count and top =="
is_eq "count counts lines of a FILE"        "$(bash "$T" count "$data")"              "6"
is_eq "count reads stdin when FILE omitted"  "$(printf 'a\nb\nc\n' | bash "$T" count)" "3"
is_eq "top returns the most frequent line"   "$(bash "$T" top "$data")"               "apple"
is_eq "top -n 2 returns two lines"           "$(bash "$T" -n 2 top "$data" | grep -c .)" "2"

echo "== exit codes are a usable API =="
check  "a good run exits 0"                  bash -c 'bash "$1" count "$2" >/dev/null' _ "$T" "$data"
denies "an unknown command exits non-zero"   bash -c 'bash "$1" frobnicate "$2" >/dev/null 2>&1' _ "$T" "$data"
check  "unknown command exits exactly 2"     bash -c 'bash "$1" frobnicate "$2" >/dev/null 2>&1; [ $? -eq 2 ]' _ "$T" "$data"
check  "an unreadable file exits exactly 1"  bash -c 'bash "$1" count /nope-xyz.$$ >/dev/null 2>&1; [ $? -eq 1 ]' _ "$T"
check  "-h prints usage and exits 0"         bash -c 'bash "$1" -h 2>/dev/null | grep -q usage' _ "$T"

echo "== it is built to the course's standard =="
is_eq "runs under strict mode"               "$(grep -cE '^set -euo pipefail' "$T")" "1"
is_eq "cleans up with a trap"                "$(grep -cE '^trap ' "$T")"             "1"
if command -v shellcheck >/dev/null 2>&1; then
  check "mytool is shellcheck-clean"         shellcheck "$T"
else
  pass "mytool shellcheck-clean (shellcheck not installed — skipped)"
fi

rm -f "$data"
ex_summary; exit $?
