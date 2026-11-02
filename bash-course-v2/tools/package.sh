#!/usr/bin/env bash
# package.sh — build the two edition archives.
#   bash tools/package.sh            (from bash-course-v2/) — the all-platform master
#   V2=build/macos SUFFIX=-macos DIST=dist bash tools/package.sh   — one platform edition
#   bash tools/package-all.sh        — master + the three platform editions
# Student: v2 student pages + env + README + the v1 executable bundle WITHOUT
#          solutions, the capstone walkthrough, prove_all.sh and v1 course pages.
# Trainer: everything in both trees.
set -euo pipefail
V2="${V2:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"; V2="$(cd "$V2" && pwd)"
V1="${V1:-$(cd "$V2/../bash-course" && pwd)}"
SUFFIX="${SUFFIX:-}"
if [[ -n "${DIST:-}" ]]; then DIST="$(mkdir -p "$DIST" && cd "$DIST" && pwd)"; else DIST="$V2/dist"; rm -rf "$DIST"; mkdir -p "$DIST"; fi
stage="$(mktemp -d "${TMPDIR:-/tmp}/package.XXXXXX")"
# shellcheck disable=SC2154
trap 'rc=$?; rm -rf "$stage"; exit "$rc"' EXIT INT TERM

# scrub scratch state that must never ship
clean_tree() {
  find "$1" \( -name work -o -name .render -o -name __pycache__ \) -type d -prune -exec rm -rf {} + 2>/dev/null || true
  find "$1" -name '*.lock' -delete
}

echo "== student =="
S="$stage/bash-course-v2-student$SUFFIX"; mkdir -p "$S"
cp -r "$V2/student" "$V2/env" "$S/"
cp "$V2/README-STUDENT.md" "$S/README.md"
cp -r "$V1/labs" "$V1/logsleuth" "$V1/seed" "$V1/program" "$V1/tools-check.sh" "$V1/grade-all.sh" "$S/"
rm -rf "$S"/labs/*/exercise/solution "$S/labs/capstone/lab.sh"
clean_tree "$S"
( cd "$stage" && zip -qrX "$DIST/bash-course-v2-student$SUFFIX.zip" "bash-course-v2-student$SUFFIX" )
echo "  $(unzip -Z1 "$DIST/bash-course-v2-student$SUFFIX.zip" | wc -l) entries"

echo "== trainer =="
T="$stage/bash-course-v2-trainer$SUFFIX"; mkdir -p "$T"
cp -r "$V2/student" "$V2/trainer" "$V2/env" "$V2/tools" "$V2/00-BRIEF-AND-BLUEPRINT.md" "$V2/CONTINUATION-MANIFEST.md" "$T/"
[[ -f "$V2/EDITION.txt" ]] && cp "$V2/EDITION.txt" "$T/" && cp "$V2/EDITION.txt" "$S/"
cp "$V2/README-TRAINER.md" "$T/README.md"; cp "$V2/README-STUDENT.md" "$T/README-STUDENT.md"
mkdir -p "$T/v1-bundle" && cp -r "$V1"/. "$T/v1-bundle/"
clean_tree "$T"
( cd "$stage" && zip -qrX "$DIST/bash-course-v2-trainer$SUFFIX.zip" "bash-course-v2-trainer$SUFFIX" )
echo "  $(unzip -Z1 "$DIST/bash-course-v2-trainer$SUFFIX.zip" | wc -l) entries"

echo "== leak check (student) =="
bash "$V2/tools/leakcheck.sh" "$DIST/bash-course-v2-student$SUFFIX.zip"
