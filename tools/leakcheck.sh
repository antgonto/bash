#!/usr/bin/env bash
# leakcheck.sh — release gate for the Student Edition archive.
#   bash tools/leakcheck.sh dist/bash-course-student.zip
# Exit 0 only when nothing trainer-only, no scratch state and no digest is inside.
set -euo pipefail
zip="${1:?usage: leakcheck.sh STUDENT.zip}"
fail=0
say() { printf '  %s\n' "$*"; }
listing="$(unzip -Z1 "$zip")"

echo "== forbidden paths =="
for pat in '/solution/' 'labs/capstone/lab.sh' '/trainer/' 'callouts' 'a10r' 'CONTINUATION-MANIFEST' 'BLUEPRINT.md' \
           'README-TRAINER' 'prove_all.sh' 'manuals/instructor' 'manuals/src' '-instructor.pdf' '/work/' '/.render/' '.lock' '__pycache__'; do
  if hits="$(grep -F -- "$pat" <<<"$listing")"; then say "LEAK  $pat"; printf '        %s\n' "$hits" | head -5; fail=1; else say "ok    no $pat"; fi
done

echo "== forbidden content =="
tmp="$(mktemp -d "${TMPDIR:-/tmp}/leakcheck.XXXXXX")"
# shellcheck disable=SC2154
trap 'rc=$?; rm -rf "$tmp"; exit "$rc"' EXIT INT TERM
unzip -q "$zip" -d "$tmp"
if grep -rl 'TRAINER ONLY' "$tmp" >/dev/null; then say "LEAK  'TRAINER ONLY' text:"; grep -rl 'TRAINER ONLY' "$tmp" | sed "s|$tmp/||; s/^/        /"; fail=1; else say "ok    no 'TRAINER ONLY' text"; fi
if grep -rEl 'sha256:[0-9a-f]{64}' "$tmp" >/dev/null; then say "LEAK  a 64-hex digest is present (digests are recorded by learners, never shipped):"; grep -rEl 'sha256:[0-9a-f]{64}' "$tmp" | sed "s|$tmp/||; s/^/        /"; fail=1; else say "ok    no shipped digest"; fi
if grep -rEl 'CAP-01R.*(F[1-7]|inject)' "$tmp"/*/student 2>/dev/null | grep -v CAP01 >/dev/null; then say "LEAK  fault-list reference outside the CAP-01 brief"; fail=1; else say "ok    no fault list"; fi

if command -v pdftotext >/dev/null 2>&1; then
  leak=0
  for pdf in "$tmp"/*/manuals/student/*.pdf; do
    [[ -f "$pdf" ]] || continue
    if pdftotext "$pdf" - 2>/dev/null | grep -qE 'Instructor (Note|Version)|^Answer:'; then say "LEAK  instructor text in ${pdf#"$tmp"/}"; leak=1; fi
  done
  if (( leak )); then fail=1; else say "ok    no instructor text in the student manuals"; fi
else
  say "skip  pdftotext not installed; student manuals not scanned"
fi

echo "== the inherited app is shipped unmodified (its planted example keys are Course 2's finding, not a leak) =="
if grep -q 'AKIAIOSFODNN7EXAMPLE' "$tmp"/*/labs/lab9-stackctl/exercise/starter/app/config.py 2>/dev/null; then say "ok    baseline config.py present with its documented example key (expected)"; else say "MISSING the baseline's config.py as inherited"; fail=1; fi
if grep -rEl 'AKIA[0-9A-Z]{16}' "$tmp" | grep -v 'starter/app/config.py' | grep -v 'COURSE0-NOTE\|student/\|RUNBOOK' >/dev/null; then say "LEAK  an AWS-style key outside the inherited app"; fail=1; else say "ok    no key material outside the inherited app"; fi

echo "== required files =="
for req in 'student/M00-' 'student/M09-' 'student/A10-' 'student/CAP01-' 'labs/lab9-stackctl/exercise/grade.sh' 'labs/lab9-stackctl/exercise/starter/bin/stackctl' 'labs/lab9-stackctl/exercise/starter/app/Dockerfile.course' 'labs/lab9-stackctl/exercise/starter/app/COURSE0-NOTE.md' 'grade-all.sh' '/README.md' 'logsleuth/bin/logsleuth' 'program/ci/sarif_gate.sh' 'program/fixtures/nuclei-unauth.sarif' 'program/fixtures/attestation.json' 'program/Makefile' 'program/README.md' 'manuals/student/lab0-first-script.pdf' 'manuals/student/lab9-stackctl.pdf' 'manuals/student/cap01-capstone-live.pdf'; do
  if grep -qF -- "$req" <<<"$listing"; then say "ok    $req"; else say "MISSING $req"; fail=1; fi
done

echo
if (( fail == 0 )); then echo "LEAKCHECK PASS: $zip"; else echo "LEAKCHECK FAIL: $zip"; exit 1; fi
