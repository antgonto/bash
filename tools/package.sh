#!/usr/bin/env bash
# package.sh — build the Student and Trainer archives from one course tree.
#   bash tools/package.sh                                  # the all-platform master → dist/
#   ROOT=build/macos SUFFIX=-macos DIST=dist bash tools/package.sh   # one platform edition
#   bash tools/package-all.sh                              # master + the three platform editions
#
# Student archive: student pages, env, labs (without solutions and the capstone walkthrough),
#                  logsleuth, seed, program, tools-check.sh, grade-all.sh, README-STUDENT.md as README.md.
# Trainer archive: everything in the tree.
set -euo pipefail
ROOT="${ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"; ROOT="$(cd "$ROOT" && pwd)"
SUFFIX="${SUFFIX:-}"
if [[ -n "${DIST:-}" ]]; then DIST="$(mkdir -p "$DIST" && cd "$DIST" && pwd)"; else DIST="$ROOT/dist"; rm -rf "$DIST"; mkdir -p "$DIST"; fi
stage="$(mktemp -d "${TMPDIR:-/tmp}/package.XXXXXX")"
# shellcheck disable=SC2154
trap 'rc=$?; rm -rf "$stage"; exit "$rc"' EXIT INT TERM

# scrub scratch state that must never ship
clean_tree() {
  find "$1" \( -name work -o -name .render -o -name __pycache__ -o -name dist -o -name build -o -name .git \) -type d -prune -exec rm -rf {} + 2>/dev/null || true
  find "$1" -name '*.lock' -delete
}

echo "== student =="
S="$stage/bash-course-student$SUFFIX"; mkdir -p "$S"
cp -r "$ROOT/student" "$ROOT/env" "$ROOT/labs" "$ROOT/logsleuth" "$ROOT/seed" "$ROOT/program" \
      "$ROOT/tools-check.sh" "$ROOT/grade-all.sh" "$S/"
cp "$ROOT/README-STUDENT.md" "$S/README.md"
[[ -f "$ROOT/EDITION.txt" ]] && cp "$ROOT/EDITION.txt" "$S/"
rm -rf "$S"/labs/*/exercise/solution "$S/labs/capstone/lab.sh"
clean_tree "$S"
( cd "$stage" && zip -qrX "$DIST/bash-course-student$SUFFIX.zip" "bash-course-student$SUFFIX" )
echo "  $(unzip -Z1 "$DIST/bash-course-student$SUFFIX.zip" | wc -l) entries"

echo "== trainer =="
T="$stage/bash-course-trainer$SUFFIX"; mkdir -p "$T"
cp -r "$ROOT"/. "$T/"
rm -f "$T/README.md"; cp "$ROOT/README-TRAINER.md" "$T/README.md"
clean_tree "$T"
( cd "$stage" && zip -qrX "$DIST/bash-course-trainer$SUFFIX.zip" "bash-course-trainer$SUFFIX" )
echo "  $(unzip -Z1 "$DIST/bash-course-trainer$SUFFIX.zip" | wc -l) entries"

echo "== leak check (student) =="
bash "$ROOT/tools/leakcheck.sh" "$DIST/bash-course-student$SUFFIX.zip"
