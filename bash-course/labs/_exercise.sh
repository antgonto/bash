#!/usr/bin/env bash
# _exercise.sh — shared harness for the student-authored lab exercises.
#
# A lab's grade.sh sources this, calls  ex_setup <lab-id> <exercise-dir>,  then
# makes assertions against "$TARGET" and ends with  ex_summary.
#
# TARGET selection:
#   - GRADE_TARGET set (CI / prove_all): grade that directory (the reference
#     solution/), so the whole course stays ALL GREEN.
#   - otherwise: grade <exercise-dir>/work, which is seeded from starter/ on the
#     first run — that is the copy you edit.
set -uo pipefail

P=0; F=0

ex_setup() {
  LAB_ID="$1"; EX_DIR="$2"
  STARTER="$EX_DIR/starter"
  SOLUTION="$EX_DIR/solution"
  WORK="$EX_DIR/work"
  if [[ -n "${GRADE_TARGET:-}" ]]; then
    TARGET="$GRADE_TARGET"
  else
    TARGET="$WORK"
    if [[ ! -d "$WORK" ]]; then
      cp -r "$STARTER" "$WORK"
      echo "note: created your working copy at"
      echo "        $WORK"
      echo "      edit the TODOs there, then re-run this grader."
      echo
    fi
  fi
  if [[ ! -d "$TARGET" ]]; then
    echo "error: target directory not found: $TARGET" >&2
    exit 2
  fi
  export TARGET LAB_ID
}

pass() { printf '  PASS: %s\n' "$1"; P=$((P+1)); }
fail() { printf '  FAIL: %s\n' "$1"; [[ -n "${2:-}" ]] && printf '        %s\n' "$2"; F=$((F+1)); }

# assertion helpers
is_eq()    { if [[ "$2" == "$3" ]]; then pass "$1"; else fail "$1" "expected [$3], got [$2]"; fi; }
contains() { if [[ "$2" == *"$3"* ]]; then pass "$1"; else fail "$1" "expected to contain [$3], got [$2]"; fi; }
check()    { if "${@:2}" >/dev/null 2>&1; then pass "$1"; else fail "$1"; fi; }        # cmd must succeed
denies()   { if ! "${@:2}" >/dev/null 2>&1; then pass "$1"; else fail "$1" "expected a non-zero exit"; fi; }  # cmd must fail

ex_summary() {
  echo
  printf -- '---- %s: %d passed, %d failed ----\n' "$LAB_ID" "$P" "$F"
  [[ "$F" -eq 0 ]]
}
