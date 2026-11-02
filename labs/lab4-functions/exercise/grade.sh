#!/usr/bin/env bash
# Lab 4 grader — checks YOUR classify.sh (work/ copy, or GRADE_TARGET for CI).
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$HERE/../../_exercise.sh"
ex_setup lab4 "$HERE"

# shellcheck source=/dev/null
source "$TARGET/classify.sh"

echo "== is_valid_status: a predicate (status, not output) =="
check  "200 is valid"            is_valid_status 200
check  "404 is valid"            is_valid_status 404
denies "999 is not valid (9xx)"  is_valid_status 999
denies "'4xx' is not valid"      is_valid_status 4xx
denies "'20' is not valid"       is_valid_status 20

echo "== status_class: a producer (prints to stdout) =="
is_eq "404 -> 4xx"       "$(status_class 404)" "4xx"
is_eq "503 -> 5xx"       "$(status_class 503)" "5xx"
is_eq "200 -> 2xx"       "$(status_class 200)" "2xx"
is_eq "junk -> unknown"  "$(status_class nope)" "unknown"

ex_summary; exit $?
