#!/usr/bin/env bash
# Lab 1 grader — checks YOUR params.sh (work/ copy, or GRADE_TARGET for CI).
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$HERE/../../_exercise.sh"
ex_setup lab1 "$HERE"

# shellcheck source=/dev/null
source "$TARGET/params.sh"

echo "== stem: basename minus a .log suffix =="
is_eq "stem /var/log/nginx/access.log -> access" "$(stem /var/log/nginx/access.log)" "access"
is_eq "stem auth.log -> auth"                     "$(stem auth.log)"                   "auth"
is_eq "stem a/b/c/app -> app (no suffix to drop)" "$(stem a/b/c/app)"                  "app"

echo "== report_name: compose the filename =="
is_eq "report_name -> report-access-2026-10-16.txt" \
  "$(report_name /var/log/nginx/access.log 2026-10-16)" "report-access-2026-10-16.txt"

echo "== parse_kv: split on '=' and trim both sides =="
parse_kv "top_n = 25"
is_eq "parse_kv key"   "$KEY"   "top_n"
is_eq "parse_kv value" "$VALUE" "25"
parse_kv "  brute_threshold=10  "
is_eq "parse_kv trims around '=' and the whole line" "$KEY|$VALUE" "brute_threshold|10"

ex_summary; exit $?
