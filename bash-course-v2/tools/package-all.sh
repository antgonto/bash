#!/usr/bin/env bash
# package-all.sh — build the all-platform master archives and the three platform editions.
#   bash tools/package-all.sh        (from bash-course-v2/)
# Output: dist/bash-course-v2-{student,trainer}{,-ubuntu,-macos,-windows}.zip
set -euo pipefail
V2="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; OUT="$V2/dist"
rm -rf "$V2/dist" "$V2/build"; mkdir -p "$V2/dist"
for os in all ubuntu macos windows; do
  python3 "$V2/tools/build_os.py" --os "$os" --out "$V2/build/$os"
  suffix=""; [[ "$os" != all ]] && suffix="-$os"
  echo "==== edition: $os ===="
  tree="$V2/build/$os"; v1="$V2/../bash-course"; pkg="$V2/tools/package.sh"
  V1="$v1" V2="$tree" SUFFIX="$suffix" DIST="$OUT" bash "$pkg"
done
ls -la "$V2/dist"
