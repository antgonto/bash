# shellcheck shell=bash
# _lib.sh — shared harness for every lab. Source it; don't run it.
#
# Each lab is an autograder: it exercises the bash feature it teaches AND the
# matching capability of the course project (logsleuth), printing PASS/FAIL for
# every claim and a `---- lab: N passed, M failed ----` summary that prove_all.sh
# consumes. Everything runs offline with only bash + coreutils + grep/sed/awk.
set -uo pipefail

# where the finished project lives (the reference the labs exercise)
COURSE_ROOT="${COURSE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export COURSE_ROOT
LOGSLEUTH="$COURSE_ROOT/logsleuth/bin/logsleuth"
export LOGSLEUTH
# run the tool NOEXEC-safely (the outputs FS blocks direct ./ execution)
logsleuth() { bash "$LOGSLEUTH" "$@"; }
export -f logsleuth

# a clean scratch dir per lab run, wiped first so a lab is idempotent
lab_workdir() {        # $1 = lab name
  local d="${LAB_WORK:-/tmp/bash-course-work}/$1"
  rm -rf "$d"; mkdir -p "$d"; printf '%s\n' "$d"
}

# generate the deterministic fixture logs a lab needs, into $1
make_fixtures() { bash "$COURSE_ROOT/seed/make_logs.sh" "$1" >/dev/null; }

# ---- assertions ----
P=0; F=0
pass() { P=$((P+1)); printf '  PASS: %s\n' "$1"; }
fail() { F=$((F+1)); printf '  FAIL: %s\n' "$1"; }
check()    { local m="$1"; shift; if "$@"; then pass "$m"; else fail "$m"; fi; }   # check "msg" cmd...
# compare helpers (so a check reads as one line)
eq()       { [ "$1" = "$2" ]; }
is_eq()    { local m="$1" got="$2" want="$3"; if [ "$got" = "$want" ]; then pass "$m"; else fail "$m (got '$got' want '$want')"; fi; }
contains() { local m="$1" hay="$2" needle="$3"; case "$hay" in *"$needle"*) pass "$m";; *) fail "$m (missing '$needle' in: ${hay:0:120})";; esac; }
file_has() { grep -qF -- "$2" "$1"; }
runs_clean() { "$@" >/dev/null 2>&1; }       # exit 0
fails_with() { local want="$1"; shift; "$@" >/dev/null 2>&1; [ "$?" -eq "$want" ]; }

summary() {           # $1 = lab label
  echo "---- $1: $P passed, $F failed ----"
  [ "$F" -eq 0 ]
}
