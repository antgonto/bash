#!/usr/bin/env bash
# Lab 4 — Functions and structure: parameters, `local`, returning a STATUS vs
# producing OUTPUT, and splitting code into a sourced library. Project milestone:
# logsleuth is already organized this way (bin + lib/util,parse,report); you
# source its library and call its functions directly.
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/../_lib.sh"
W="$(lab_workdir lab4)"; cd "$W" || exit 1; make_fixtures "$W/fx"

echo "== a function takes positional args \$1..\$@, like a script =="
greet() { printf 'hello, %s\n' "$1"; }
is_eq "function arg \$1" "$(greet Antonio)" "hello, Antonio"
count_args() { echo "$#"; }
is_eq "\$# counts arguments" "$(count_args a b c)" "3"

echo "== local keeps variables from leaking into the caller =="
leaky()   { x=leaked; }
careful() { local x=safe; echo "$x"; }
x=outer; leaky;   is_eq "WITHOUT local the global is clobbered" "$x" "leaked"
x=outer; careful >/dev/null; is_eq "WITH local the global is untouched" "$x" "outer"

echo "== two ways a function gives a result: STATUS vs OUTPUT =="
# status: return 0/non-zero, consumed by if / && (a predicate)
is_valid_status() { [[ "$1" =~ ^[1-5][0-9][0-9]$ ]]; }
check "predicate returns success for 404" is_valid_status 404
if ! is_valid_status xx; then pass "predicate returns failure for 'xx'"; else fail "predicate accepted 'xx'"; fi
# output: print to stdout, captured with $( )
status_class() { echo "${1:0:1}xx"; }
is_eq "function output captured" "$(status_class 404)" "4xx"
# the anti-pattern: don't `echo` a result AND rely on `return N` for the value —
# return is 0..255 only; use it for status, stdout for data.
answer() { echo 42; return 0; }
is_eq "data comes from stdout, not return" "$(answer)" "42"

echo "== explicit return codes drive callers =="
classify() { case "$1" in 2*) return 0;; 4*) return 1;; 5*) return 2;; *) return 3;; esac; }
classify 200; is_eq "2xx -> 0" "$?" "0"
classify 404; is_eq "4xx -> 1" "$?" "1"
classify 500; is_eq "5xx -> 2" "$?" "2"

echo "== a library is a file you SOURCE to reuse functions =="
cat > mathlib.sh <<'EOF'
# shellcheck shell=bash
add() { echo $(( $1 + $2 )); }
EOF
# shellcheck source=/dev/null
source ./mathlib.sh
is_eq "sourced function is callable" "$(add 40 2)" "42"

echo "== the project: source logsleuth's own library and call its functions =="
# the real tool is just functions in lib/*.sh behind a thin bin/ dispatcher.
# source them (as bin/logsleuth does) and drive the parser directly.
export TOP_N=10 BRUTE_THRESHOLD=10
# shellcheck source=/dev/null
source "$COURSE_ROOT/logsleuth/lib/util.sh"
# shellcheck source=/dev/null
source "$COURSE_ROOT/logsleuth/lib/parse.sh"
is_eq "parse.field_status counts match the fixture" \
  "$(field_status "$W/fx/access.log" | grep -c '^200$')" "85"
is_eq "parse.failed_login_ips extracts the attacker IP" \
  "$(failed_login_ips "$W/fx/auth.log" | sort -u | grep -c '203.0.113.9')" "1"
is_eq "parse.count_col gives the top talker first" \
  "$(count_col "$W/fx/access.log" 1 1 | awk '{print $2}')" "10.0.0.1"
# util.load_config mutates TOP_N as data (never executing the file)
printf 'top_n = 7\n' > c.conf; load_config ./c.conf
is_eq "load_config set TOP_N from the file" "$TOP_N" "7"
cleanup   # the lib registered a temp dir at source time; prove cleanup is a no-fail

summary lab4
