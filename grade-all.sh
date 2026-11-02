#!/usr/bin/env bash
# grade-all.sh — your exercise dashboard. Runs every lab's grader against YOUR
# work (labs/<lab>/exercise/work/, seeded from the starter the first time).
# Edit the work/ files, then re-run this to watch the FAILs turn into PASSes.
#
# Grade a single lab instead:   bash labs/lab3-loops-arrays/exercise/grade.sh
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

labs=(lab0-first-script lab1-variables lab2-conditionals lab3-loops-arrays
      lab4-functions lab5-text-processing lab6-arguments lab7-robustness
      lab8-testing lab9-stackctl capstone)

fail=0
echo "Your exercises (edit labs/<lab>/exercise/work/, then re-run):"
for l in "${labs[@]}"; do
  ex="$HERE/labs/$l/exercise"
  [ -f "$ex/grade.sh" ] || continue
  line="$(bash "$ex/grade.sh" 2>&1 | grep -E '^---- ')"
  printf '  %-22s %s\n' "$l" "${line:-NO SUMMARY}"
  echo "$line" | grep -q ' 0 failed ----' || fail=1
done

echo
if [ "$fail" -eq 0 ]; then
  echo "ALL GREEN — every exercise passes. You built the tool."
else
  echo "Some exercises still have FAILs. Open that lab's exercise/TASK.md and"
  echo "edit its exercise/work/ files, then run this again."
fi
exit "$fail"
