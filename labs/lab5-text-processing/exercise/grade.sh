#!/usr/bin/env bash
# Lab 5 grader — checks YOUR reports.sh against deterministic fixture logs.
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
# shellcheck source=/dev/null
source "$HERE/../../_exercise.sh"
ex_setup lab5 "$HERE"

# shellcheck source=/dev/null
source "$TARGET/reports.sh"

fx="$(mktemp -d)"
bash "$ROOT/seed/make_logs.sh" "$fx" >/dev/null
A="$fx/access.log"

echo "== top_ips: the counting pipeline =="
is_eq "top IP is 10.0.0.1 with 50"       "$(top_ips "$A" 1)" "10.0.0.1 50"
is_eq "top_ips N=3 returns 3 lines"       "$(top_ips "$A" 3 | grep -c .)" "3"

echo "== count_class: awk filter by status class =="
is_eq "4xx count is 50" "$(count_class "$A" 4)" "50"
is_eq "5xx count is 5"  "$(count_class "$A" 5)" "5"
is_eq "2xx count is 85" "$(count_class "$A" 2)" "85"

rm -rf "$fx"
ex_summary; exit $?
