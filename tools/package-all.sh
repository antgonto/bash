#!/usr/bin/env bash
# package-all.sh — build the all-platform master archives and the three platform editions.
#   bash tools/package-all.sh        (from the course root)
# Output: dist/bash-course-{student,trainer}{,-ubuntu,-macos,-windows}.zip
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; OUT="$ROOT/dist"
rm -rf "$ROOT/dist" "$ROOT/build"; mkdir -p "$ROOT/dist"
for os in all ubuntu macos windows; do
  python3 "$ROOT/tools/build_os.py" --os "$os" --out "$ROOT/build/$os"
  suffix=""; [[ "$os" != all ]] && suffix="-$os"
  echo "==== edition: $os ===="
  ROOT="$ROOT/build/$os" SUFFIX="$suffix" DIST="$OUT" bash "$ROOT/tools/package.sh"
done
ls -la "$ROOT/dist"
