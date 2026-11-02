#!/usr/bin/env bash
set -uo pipefail
: "${STAGING:=https://staging.secmlops.com}"
HOST="${STAGING#https://}"
nmap -sV -Pn -oX nmap.xml "$HOST" || true
katana -u "$STAGING" -jc -kf all -o urls-unauth.txt || true
nuclei -l urls-unauth.txt -severity medium,high,critical -sarif-export nuclei-unauth.sarif -silent || true
[ -x /tmp/testssl/testssl.sh ] || git clone -q --depth 1 https://github.com/testssl/testssl.sh /tmp/testssl
/tmp/testssl/testssl.sh --jsonfile testssl.json --quiet "$STAGING" || true
python3 to_sarif.py testssl testssl.json testssl.sarif 2>/dev/null || true
# Gate: a report that was never written is NOT a clean report (a scanner killed by a timeout must fail the stage).
sarif_gate() {  # sarif_gate FILE...  every report must exist, parse, and carry no error-level result
  for s in "$@"; do
    [ -f "$s" ] || { echo "MISSING REPORT: $s (the scanner did not run or did not write it)"; exit 1; }
    n=$(jq '[.runs[].results[] | select(.level=="error")] | length' "$s" 2>/dev/null) || n=""
    case "$n" in
      0) ;;
      "") echo "UNREADABLE REPORT: $s (not valid SARIF)"; exit 1 ;;
      *) echo "CRITICAL in $s: $n error-level finding(s)"; exit 1 ;;
    esac
  done
}
sarif_gate nuclei-unauth.sarif testssl.sarif
echo "PHASE1-DONE"
