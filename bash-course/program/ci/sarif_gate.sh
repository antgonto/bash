#!/usr/bin/env bash
# Tool-agnostic gate (Lab 13.2): fail if any SARIF result has level "error" (= critical/high after to_sarif.py's mapping).
#   ci/sarif_gate.sh file.sarif [file2.sarif ...]
set -euo pipefail
total=0
for f in "$@"; do
  n=$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(sum(1 for r in d.get('runs',[]) for x in r.get('results',[]) if x.get('level')=='error'))" "$f")
  echo "$f: $n error-level findings"; total=$((total+n))
done
[ "$total" -eq 0 ] && echo "SARIF-GATE-PASS" || { echo "CRITICAL findings: $total → exit 1"; exit 1; }
