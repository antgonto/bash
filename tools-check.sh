#!/usr/bin/env bash
# tools-check.sh — confirm a machine can run the course. The labs need only
# bash + coreutils + grep/sed/awk; shellcheck, flock, jq, curl, python3 and make
# are used by individual steps (each step names its tool and has a fallback).
set -uo pipefail
ok=0; miss=0
need() {  # name  note  cmd...
  if "${@:3}" >/dev/null 2>&1; then printf '  ok    %-10s %s\n' "$1" "$("${@:3}" 2>&1 | head -1)"; ok=$((ok+1))
  else printf '  MISS  %-10s (%s)\n' "$1" "$2"; miss=$((miss+1)); fi
}
echo "== required =="
need bash  "bash >= 4"         bash --version
need awk   "awk (gawk/mawk)"   awk --version
need sed   "sed"              sed --version
need grep  "grep"             grep --version
need sort  "coreutils"        sort --version
echo "== recommended =="
need shellcheck "the linter used in Lab 8 + the gate"  shellcheck --version
need flock      "util-linux; used in Lab 7 (locking)"  flock --version
need jq         "JSON; used in M05 S05.6/S05.8"           jq --version
need curl       "HTTP; used in M05 S05.8 and M09"        curl --version
need python3    "used in M05 S05.7/S05.8 and M08 S08.5"  python3 --version
need make       "used in the M04 Makefile reading"       make --version
echo
bv="$(bash -c 'echo "${BASH_VERSINFO[0]}"')"
if [ "${bv:-0}" -ge 4 ]; then echo "bash $bv OK (associative arrays need >= 4; macOS ships 3.2 — install via brew)"; fi
if [ "$miss" -eq 0 ]; then echo "ready: $ok tools present"; else echo "$ok present, $miss missing (the labs need only bash+coreutils+awk/sed/grep)"; fi
