#!/usr/bin/env bash
# Lab 2 — Conditionals: if, [[ ]] vs [ ], file/string/number tests, && / ||, and
# case. Project milestone: logsleuth validates its input and routes subcommands
# with exactly these constructs.
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/../_lib.sh"
W="$(lab_workdir lab2)"; cd "$W" || exit 1; make_fixtures "$W/fx"

echo "== if runs a COMMAND and branches on its exit status (0 = then) =="
if true;  then r=then; else r=else; fi; is_eq "if true -> then"  "$r" "then"
if false; then r=then; else r=else; fi; is_eq "if false -> else" "$r" "else"

echo "== prefer [[ ]] over [ ]: no word-splitting, richer tests =="
empty=""
# with [ ] an empty unquoted var breaks the syntax; [[ ]] handles it safely
check "[[ -z ]] detects an empty string safely" bash -c '[[ -z "$1" ]]' _ "$empty"
check "[[ -n ]] detects a non-empty string"     bash -c '[[ -n "$1" ]]' _ "x"
# string equality and pattern matching are built into [[ ]]
check "[[ = ]] string equality"   bash -c '[[ "logsleuth" = "logsleuth" ]]'
check "[[ == pattern ]] globbing"  bash -c '[[ "access.log" == *.log ]]'
check "[[ =~ regex ]] matching"    bash -c '[[ "401" =~ ^[0-9]{3}$ ]]'

echo "== numeric tests: (( )) for arithmetic, -eq/-lt for [[ ]] =="
n=40
check "(( n > 10 )) arithmetic truth" bash -c '(( $1 > 10 ))' _ "$n"
check "[[ n -eq 40 ]]"                 bash -c '[[ $1 -eq 40 ]]' _ "$n"
is_eq "string '10' vs number: (( )) compares as numbers" "$(( '10' < '9' ? 1 : 0 ))" "0"

echo "== file tests: the checks logsleuth makes before reading a log =="
check "-f : access.log is a regular file" test -f "$W/fx/access.log"
check "-r : it is readable"               test -r "$W/fx/access.log"
check "-s : it is non-empty"              test -s "$W/fx/access.log"
check "! -e : a missing file does not exist" bash -c '[[ ! -e "$1" ]]' _ "$W/fx/nope.log"
check "-d : fx is a directory"            test -d "$W/fx"

echo "== && / || express 'do this, else that' compactly =="
is_eq "guard with || (fallback on failure)" "$(false || echo fallback)" "fallback"
# a common guard: require a file or die
msg="$( [[ -r "$W/fx/access.log" ]] && echo readable || echo missing )"
is_eq "readable-or-missing guard" "$msg" "readable"

echo "== case dispatches on a value — how logsleuth routes subcommands =="
route() { case "$1" in summary|top|errors) echo valid;; brute*) echo brute;; *) echo unknown;; esac; }
is_eq "case: known command"          "$(route summary)" "valid"
is_eq "case: prefix pattern brute*"  "$(route bruteforce)" "brute"
is_eq "case: unknown falls through"  "$(route frobnicate)" "unknown"

echo "== the project: logsleuth's own validation and routing =="
# an unreadable file is rejected with a clear error and exit 1
check "missing log -> non-zero exit (validated by -r)" bash -c '! logsleuth summary "$1/nope.log" 2>/dev/null' _ "$W/fx"
contains "missing log -> a clear message" "$(logsleuth summary "$W/fx/nope.log" 2>&1)" "cannot read log file"
# an unknown subcommand is rejected (its case '*' branch), exit 2
check "unknown subcommand -> exit 2" bash -c 'logsleuth frobnicate 2>/dev/null; [ $? -eq 2 ]'
# a valid subcommand routes correctly
contains "valid subcommand routes to its report" "$(logsleuth summary "$W/fx/access.log")" "Summary"

summary lab2
