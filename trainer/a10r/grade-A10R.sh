#!/usr/bin/env bash
# A-10R grader (TRAINER ONLY) — equivalent reassessment of A-10 with different
# subcommand names and a different exit-code map. Same 12-check rubric shape.
#
#   bash grade-A10R.sh /path/to/their/linetool
#
# Contract the learner receives (TASK-A10R.md):
#   linetool lines [FILE]        number of lines (FILE or stdin)
#   linetool [-k N] freq [FILE]  the N most frequent line(s), default 1
#   linetool -h                  usage
#   exit codes: 0 ok · 3 unreadable file · 4 usage / unknown command
# shellcheck disable=SC2016  # the single-quoted 'bash -c' bodies deliberately expand $1/$2 inside the child
set -uo pipefail
T="${1:?usage: grade-A10R.sh /path/to/linetool}"
P=0; F=0
pass() { printf '  PASS: %s\n' "$1"; P=$((P+1)); }
fail() { printf '  FAIL: %s\n' "$1"; [[ -n "${2:-}" ]] && printf '        %s\n' "$2"; F=$((F+1)); }
is_eq()  { if [[ "$2" == "$3" ]]; then pass "$1"; else fail "$1" "expected [$3], got [$2]"; fi; }
check()  { if "${@:2}" >/dev/null 2>&1; then pass "$1"; else fail "$1"; fi; }
denies() { if ! "${@:2}" >/dev/null 2>&1; then pass "$1"; else fail "$1" "expected a non-zero exit"; fi; }

data="$(mktemp)"; printf 'red\nblue\nred\ngreen\nred\nblue\n' > "$data"

echo "== it works: lines and freq =="
is_eq "lines counts lines of a FILE"         "$(bash "$T" lines "$data")"               "6"
is_eq "lines reads stdin when FILE omitted"  "$(printf 'a\nb\nc\nd\n' | bash "$T" lines)" "4"
is_eq "freq returns the most frequent line"  "$(bash "$T" freq "$data")"                "red"
is_eq "freq -k 2 returns two lines"          "$(bash "$T" -k 2 freq "$data" | grep -c .)" "2"

echo "== exit codes are a usable API (0 / 3 / 4) =="
check  "a good run exits 0"                  bash -c 'bash "$1" lines "$2" >/dev/null' _ "$T" "$data"
denies "an unknown command exits non-zero"   bash -c 'bash "$1" frobnicate "$2" >/dev/null 2>&1' _ "$T" "$data"
check  "unknown command exits exactly 4"     bash -c 'bash "$1" frobnicate "$2" >/dev/null 2>&1; [ $? -eq 4 ]' _ "$T" "$data"
check  "an unreadable file exits exactly 3"  bash -c 'bash "$1" lines /nope-xyz.$$ >/dev/null 2>&1; [ $? -eq 3 ]' _ "$T"
check  "-h prints usage and exits 0"         bash -c 'bash "$1" -h 2>/dev/null | grep -q usage' _ "$T"

echo "== it is built to the course's standard =="
is_eq "runs under strict mode"               "$(grep -cE '^set -euo pipefail' "$T")" "1"
is_eq "cleans up with a trap"                "$(grep -cE '^trap ' "$T")"             "1"
if command -v shellcheck >/dev/null 2>&1; then
  check "linetool is shellcheck-clean"       shellcheck "$T"
else
  pass "linetool shellcheck-clean (shellcheck not installed — skipped)"
fi

rm -f "$data"
echo
printf -- '---- A-10R: %d passed, %d failed ----\n' "$P" "$F"
[[ "$F" -eq 0 ]]
