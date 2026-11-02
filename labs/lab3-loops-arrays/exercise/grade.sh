#!/usr/bin/env bash
# Lab 3 grader — checks YOUR counters.sh against deterministic fixture logs.
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"     # the bash-course/ root
# shellcheck source=/dev/null
source "$HERE/../../_exercise.sh"
ex_setup lab3 "$HERE"

# shellcheck source=/dev/null
source "$TARGET/counters.sh"

fx="$(mktemp -d)"
bash "$ROOT/seed/make_logs.sh" "$fx" >/dev/null

echo "== count_status: status codes by associative array =="
out="$(count_status "$fx/access.log")"
contains "200 count is 85" "$out" "200 85"
contains "401 count is 40" "$out" "401 40"
contains "500 count is 5"  "$out" "500 5"

echo "== bruteforce_count: failed logins per IP =="
is_eq "203.0.113.9 has 25 failed logins" "$(bruteforce_count "$fx/auth.log" 203.0.113.9)" "25"
is_eq "an innocent IP has 0"             "$(bruteforce_count "$fx/auth.log" 10.0.0.1)"     "0"

rm -rf "$fx"
ex_summary; exit $?
