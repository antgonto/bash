#!/usr/bin/env bash
# Lab 7 grader — checks YOUR worker.sh cleans up and preserves its exit code.
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$HERE/../../_exercise.sh"
ex_setup lab7 "$HERE"

W="$TARGET/worker.sh"
marker="$(mktemp)"

echo "== exit code survives the cleanup trap =="
bash "$W" "$marker" 0; code=$?
is_eq "exit 0 is preserved" "$code" "0"
d0="$(cat "$marker")"
check "temp dir removed after exit 0" test ! -d "$d0"

bash "$W" "$marker" 3; code=$?
is_eq "exit 3 is preserved through the trap" "$code" "3"
d3="$(cat "$marker")"
check "temp dir removed after exit 3" test ! -d "$d3"

echo "== no temp leak across repeated runs =="
before="$(find "${TMPDIR:-/tmp}" -maxdepth 1 -name 'lab7.*' 2>/dev/null | grep -c . || true)"
for _ in 1 2 3; do bash "$W" "$marker" 0 >/dev/null; done
after="$(find "${TMPDIR:-/tmp}" -maxdepth 1 -name 'lab7.*' 2>/dev/null | grep -c . || true)"
is_eq "three runs leave no temp dirs behind" "$after" "$before"

echo "== quality =="
if command -v shellcheck >/dev/null 2>&1; then
  check "worker.sh is shellcheck-clean" shellcheck "$W"
else
  pass "worker.sh shellcheck-clean (shellcheck not installed — skipped)"
fi

rm -f "$marker"
ex_summary; exit $?
