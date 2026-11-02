#!/usr/bin/env bash
# Lab 7 — Robustness: strict mode and its traps, signal-safe cleanup with
# mktemp + trap, the EXIT-status gotcha, and a lock file with flock. Project
# milestone: logsleuth never leaks a temp file and its exit codes survive the
# cleanup trap.
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/../_lib.sh"
W="$(lab_workdir lab7)"; cd "$W" || exit 1; make_fixtures "$W/fx"

echo "== set -e has sharp edges you must know =="
# a function that returns non-zero as the LAST command aborts the caller under -e
# ...unless its result is CONSUMED by if/&&/||. This is the #1 -e surprise.
is_eq "a non-zero command in an if-condition does NOT abort -e" \
  "$(bash -c 'set -e; if grep -q zzz <<<"abc"; then echo y; else echo n; fi')" "n"
# the (( )) trap: (( x++ )) returns FAILURE when x was 0, aborting -e
is_eq "(( x++ )) when x=0 returns failure" \
  "$(bash -c 'x=0; if (( x++ )); then echo t; else echo f; fi')" "f"
is_eq "pre-increment (( ++x )) is safe" \
  "$(bash -c 'set -e; x=0; (( ++x )); echo "$x"')" "1"

echo "== trap EXIT runs on ANY exit — the place to clean up =="
cat > exits.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
d="$(mktemp -d)"
trap 'rm -rf "$d"; echo "cleaned" >&2' EXIT
echo "working in $d"
exit "${1:-0}"
EOF
err="$(bash exits.sh 0 2>&1 >/dev/null)"; is_eq "cleanup runs on success" "$err" "cleaned"
err="$(bash exits.sh 5 2>&1 >/dev/null)"; is_eq "cleanup runs on failure too" "$err" "cleaned"

echo "== the EXIT-trap STATUS gotcha (what logsleuth gets right) =="
# WITHOUT set -e, the trap's own status does not change the script's exit code
bash -c 'trap "false" EXIT; exit 0'; is_eq "no set -e: a failing EXIT trap leaves exit 0" "$?" "0"
# UNDER set -e, a failing command INSIDE the trap triggers set -e and clobbers to 1 —
# even if the cleanup function would later `return 0` (it never gets there)
bash -c 'set -e; trap "false" EXIT; exit 0'; is_eq "set -e: a failing trap command clobbers exit 0 -> 1" "$?" "1"
# the only reliable fix (and what logsleuth's bin does): capture \$?, clean, re-exit with it
bash -c 'set -e; cleanup(){ rm -rf /nonexistent-xyz 2>/dev/null || true; }
         trap "rc=\$?; cleanup; exit \$rc" EXIT; exit 3'
is_eq "capture-and-reexit preserves the real code (3)" "$?" "3"

echo "== signal-safe cleanup: a temp dir survives nothing, not even SIGTERM =="
cat > worker.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
d="$(mktemp -d "${TMPDIR:-/tmp}/lab7work.XXXXXX")"
trap 'rc=$?; rm -rf "$d"; exit "$rc"' EXIT INT TERM   # TERM/INT funnel into EXIT
echo "$d" > "$1"          # publish our temp path so the test can watch it
while true; do sleep 0.2; done
EOF
marker="$W/marker"; bash worker.sh "$marker" & wpid=$!
for _ in $(seq 1 50); do [[ -s "$marker" ]] && break; sleep 0.1; done
tmpdir="$(cat "$marker")"
check "the worker created its temp dir" test -d "$tmpdir"
kill -TERM "$wpid"; wait "$wpid" 2>/dev/null || true
check "after SIGTERM the temp dir is gone (trap TERM->EXIT cleaned it)" test ! -d "$tmpdir"

echo "== flock serializes writers so a shared file isn't corrupted =="
# two processes append 200 lines each to one file, each append under a lock
writer() { local i; for i in $(seq 1 200); do
  flock "$W/out.lock" bash -c 'printf "%s\n" "$1" >> "$2"' _ "line-$i-$3" "$W/out.txt"
done; }
: > "$W/out.txt"
writer a 1 A & writer b 2 B & wait
is_eq "both writers' lines all present (no lost writes)" "$(wc -l < "$W/out.txt")" "400"
is_eq "every line is intact (no interleaved corruption)" \
  "$(grep -c '^line-[0-9]*-[AB]$' "$W/out.txt")" "400"

echo "== the project: logsleuth leaks nothing and keeps its exit codes =="
rm -f /tmp/logsleuth.* 2>/dev/null; rm -rf /tmp/logsleuth.*/ 2>/dev/null
before="$(find /tmp -maxdepth 1 -name 'logsleuth.*' 2>/dev/null | grep -c . || true)"
for _ in 1 2 3; do logsleuth summary < "$W/fx/access.log" >/dev/null; done   # stdin => temp each time
after="$(find /tmp -maxdepth 1 -name 'logsleuth.*' 2>/dev/null | grep -c . || true)"
is_eq "three stdin runs leave zero temp files behind" "$after" "$before"
check "bruteforce's exit 3 survives the cleanup trap" \
  bash -c 'logsleuth bruteforce "$1" >/dev/null; [ $? -eq 3 ]' _ "$W/fx/auth.log"
check "the tool still runs under a hostile IFS (it sets its own where needed)" \
  bash -c 'IFS=x; logsleuth summary "$1" >/dev/null' _ "$W/fx/access.log"

summary lab7
