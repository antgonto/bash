#!/usr/bin/env bash
# prove_all.sh — run every lab's autograder and the project's own test suite,
# offline, from scratch. Exit 0 only if every check in every lab passes and the
# logsleuth suite is green and shellcheck-clean.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
export COURSE_ROOT="$HERE"
export LAB_WORK="${LAB_WORK:-/tmp/bash-course-work}"
rm -rf "$LAB_WORK"; mkdir -p "$LAB_WORK"

labs=(lab0-first-script lab1-variables lab2-conditionals lab3-loops-arrays
      lab4-functions lab5-text-processing lab6-arguments lab7-robustness
      lab8-testing lab9-stackctl capstone)
fail=0
echo "== labs =="
for l in "${labs[@]}"; do
  line="$(timeout 180 bash "$HERE/labs/$l/lab.sh" 2>&1 | grep -E '^---- ')"
  printf '  %-22s %s\n' "$l" "${line:-NO SUMMARY (lab crashed)}"
  echo "$line" | grep -q ' 0 failed ----' || fail=1
done

echo "== exercises (graded against the reference solutions) =="
for l in "${labs[@]}"; do
  ex="$HERE/labs/$l/exercise"
  [ -f "$ex/grade.sh" ] || continue
  line="$(GRADE_TARGET="$ex/solution" timeout 90 bash "$ex/grade.sh" 2>&1 | grep -E '^---- ')"
  printf '  %-22s %s\n' "$l" "${line:-NO SUMMARY (grader crashed)}"
  echo "$line" | grep -q ' 0 failed ----' || fail=1
done

echo "== project =="
suite="$(bash "$HERE/logsleuth/tests/run.sh" 2>&1 | tail -1)"
printf '  %-22s %s\n' "logsleuth tests" "$suite"
echo "$suite" | grep -q '0 failed' || fail=1
if shellcheck -x -P SCRIPTDIR "$HERE"/logsleuth/bin/logsleuth "$HERE"/logsleuth/lib/*.sh \
     "$HERE"/logsleuth/tests/*.sh "$HERE"/logsleuth/install.sh \
     "$HERE"/logsleuth/completions/logsleuth.bash >/dev/null 2>&1; then
  printf '  %-22s %s\n' "shellcheck gate" "clean"
else
  printf '  %-22s %s\n' "shellcheck gate" "FINDINGS"; fail=1
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "ALL GREEN — every bash concept is demonstrated and the logsleuth project"
  echo "it builds is correct, tested, and lint-clean."
else
  echo "FAILURES PRESENT — rerun the item above, e.g.: bash labs/<lab>/lab.sh"
fi
exit "$fail"
