#!/usr/bin/env bash
# Capstone — the finished logsleuth, proven end to end: install it, run every
# subcommand against fixtures with the right numbers and exit codes, confirm its
# test suite is green and it passes the shellcheck gate, and verify its
# robustness guarantees. This is the whole course standing up at once, and the
# template for the tool you write next.
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/../_lib.sh"
W="$(lab_workdir capstone)"; cd "$W" || exit 1; make_fixtures "$W/fx"
A="$W/fx/access.log"; AUTH="$W/fx/auth.log"

echo "== 1. it installs and runs from your PATH =="
PFX="$W/prefix"; PREFIX="$PFX" bash "$COURSE_ROOT/logsleuth/install.sh" >/dev/null
LS="$PFX/bin/logsleuth"          # the installed symlink (run NOEXEC-safely with bash)
is_eq "installed symlink resolves its lib and reports version" "$(bash "$LS" -V)" "logsleuth 1.0.0"
check "man page installed"       test -f "$PFX/share/man/man1/logsleuth.1"
check "bash completion installed" test -f "$PFX/share/bash-completion/completions/logsleuth"

echo "== 2. every subcommand gives the right answer =="
is_eq "summary: 140 requests"        "$(bash "$LS" summary "$A" | awk '/requests/{print $2}')" "140"
is_eq "summary: 4 unique IPs"        "$(bash "$LS" summary "$A" | awk '/unique/{print $3}')" "4"
is_eq "summary: 4xx class = 50"      "$(bash "$LS" summary "$A" | awk '$1=="4xx"{print $2}')" "50"
is_eq "top: #1 talker is 10.0.0.1"   "$(bash "$LS" -n1 top "$A" | awk 'NR==2{print $2}')" "10.0.0.1"
is_eq "top -f path: #1 path is /api/predict" "$(bash "$LS" -n1 -f path top "$A" | awk 'NR==2{print $2}')" "/api/predict"
is_eq "top -f status: #1 is 200"     "$(bash "$LS" -n1 -f status top "$A" | awk 'NR==2{print $2}')" "200"
is_eq "errors: 5xx=5"                "$(bash "$LS" errors "$A" | awk 'NR==1{print $3}')" "5xx=5"
contains "bruteforce flags the attacker" "$(bash "$LS" bruteforce "$AUTH")" "203.0.113.9"

echo "== 3. exit codes are a correct, usable API =="
check "summary ok -> 0"            bash -c 'bash "$1" summary "$2" >/dev/null' _ "$LS" "$A"
check "bruteforce flagged -> 3"    bash -c 'bash "$1" bruteforce "$2" >/dev/null; [ $? -eq 3 ]' _ "$LS" "$AUTH"
check "unknown command -> 2"       bash -c 'bash "$1" nope 2>/dev/null; [ $? -eq 2 ]' _ "$LS"
check "unreadable file -> 1"       bash -c 'bash "$1" summary /no/such 2>/dev/null; [ $? -eq 1 ]' _ "$LS"

echo "== 4. it composes in pipelines (reads stdin, chains on exit codes) =="
is_eq "reads stdin when no FILE"   "$(bash "$LS" summary < "$A" | awk '/requests/{print $2}')" "140"
# use bruteforce's exit 3 to drive an alert, the Unix way
alert="$(bash "$LS" bruteforce "$AUTH" >/dev/null 2>&1 && echo quiet || echo ALERT)"
is_eq "exit 3 drives an '|| alert' idiom" "$alert" "ALERT"

echo "== 5. it is correct AND clean (the suite is green; shellcheck is silent) =="
contains "the test suite passes" "$(bash "$COURSE_ROOT/logsleuth/tests/run.sh")" "0 failed"
check "test suite exits 0"       bash -c 'bash "$1/logsleuth/tests/run.sh" >/dev/null' _ "$COURSE_ROOT"
check "shellcheck: whole project, zero findings" bash -c '
  shellcheck -x -P SCRIPTDIR "$1"/logsleuth/bin/logsleuth "$1"/logsleuth/lib/*.sh \
    "$1"/logsleuth/tests/*.sh "$1"/logsleuth/install.sh "$1"/logsleuth/completions/logsleuth.bash' _ "$COURSE_ROOT"

echo "== 6. robustness holds under stress =="
rm -f /tmp/logsleuth.* 2>/dev/null; rm -rf /tmp/logsleuth.*/ 2>/dev/null
b="$(find /tmp -maxdepth 1 -name 'logsleuth.*' 2>/dev/null | grep -c . || true)"
for _ in 1 2 3 4 5; do bash "$LS" summary < "$A" >/dev/null; done
a="$(find /tmp -maxdepth 1 -name 'logsleuth.*' 2>/dev/null | grep -c . || true)"
is_eq "five stdin runs leak zero temp files" "$a" "$b"
check "a config file changes behavior as data (never executed)" bash -c '
  printf "brute_threshold = 999\n" > "$1/x.conf"
  bash "$2" -c "$1/x.conf" bruteforce "$3" >/dev/null; [ $? -eq 0 ]' _ "$W" "$LS" "$AUTH"

echo
echo "== your deliverable: apply the same skeleton to a tool of your own =="
cat <<'RUBRIC'
  Write a bash tool that scores on every row below (the rubric logsleuth meets):
    [ ] #!/usr/bin/env bash + set -euo pipefail + a clear usage()
    [ ] getopts for options, a case dispatcher for subcommands
    [ ] logic in functions in a sourced lib/, not one long script
    [ ] reads a FILE argument OR stdin; quotes every expansion
    [ ] distinct exit codes (0 ok / 1 runtime / 2 usage / app-specific)
    [ ] a trap that cleans up temp files on any exit, code preserved
    [ ] a config file parsed as DATA (never sourced)
    [ ] a test suite (assert.sh-style) that is green
    [ ] zero shellcheck findings
    [ ] an install.sh, a man page, and bash completion
  Pass = the equivalent of a green prove_all.sh on your own project.
RUBRIC
summary capstone
