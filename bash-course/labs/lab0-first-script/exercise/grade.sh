#!/usr/bin/env bash
# Lab 0 grader — checks YOUR greet script (work/ copy, or GRADE_TARGET for CI).
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$HERE/../../_exercise.sh"
ex_setup lab0 "$HERE"

T="$TARGET/greet"

echo "== it runs and produces exact output =="
is_eq "default greeting"       "$(bash "$T")"         "Hello, world!"
is_eq "greets its argument"    "$(bash "$T" Antonio)" "Hello, Antonio!"
check "exits 0 on success"     bash -c 'bash "$1" >/dev/null' _ "$T"

echo "== it is built on the house frame =="
is_eq "has an env-bash shebang" "$(head -1 "$T")"                       "#!/usr/bin/env bash"
is_eq "uses strict mode"        "$(grep -cE '^set -euo pipefail' "$T")" "1"
if command -v shellcheck >/dev/null 2>&1; then
  check "greet is shellcheck-clean" shellcheck "$T"
else
  pass "greet shellcheck-clean (shellcheck not installed — skipped)"
fi

ex_summary; exit $?
