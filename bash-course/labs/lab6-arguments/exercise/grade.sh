#!/usr/bin/env bash
# Lab 6 grader — checks YOUR cli.sh (work/ copy, or GRADE_TARGET for CI).
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$HERE/../../_exercise.sh"
ex_setup lab6 "$HERE"

LIB="$TARGET/cli.sh"
# shellcheck source=/dev/null
source "$LIB"

echo "== parse_opts: getopts with defaults, options, and errors =="
is_eq "defaults when no options"   "$(parse_opts file.log)"        "n=10 v=0 rest=file.log"
is_eq "-n 5 and -v parsed"          "$(parse_opts -n 5 -v a.log)"  "n=5 v=1 rest=a.log"
is_eq "options stop at first non-option" "$(parse_opts -n 2 a.log -v)" "n=2 v=0 rest=a.log -v"
denies "missing arg to -n fails (2)"     bash -c 'source "$1"; parse_opts -n' _ "$LIB"
denies "unknown option -z fails (2)"     bash -c 'source "$1"; parse_opts -z' _ "$LIB"

echo "== read_input: file or stdin =="
tmp="$(mktemp)"; printf 'line1\nline2\n' > "$tmp"
is_eq "reads a named FILE"  "$(read_input "$tmp")"              "$(printf 'line1\nline2')"
is_eq "reads from stdin"    "$(printf 'piped\n' | read_input)" "piped"
rm -f "$tmp"

ex_summary; exit $?
