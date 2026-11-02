# shellcheck shell=bash
# Black-box tests for the bin/ dispatcher (exit codes = the CLI's API).
L="$TESTDIR/../bin/logsleuth"
assert_eq   "version string"        "$(bash "$L" -V)" "logsleuth 1.0.0"
assert_code "unknown command -> 2"  2 bash "$L" frobnicate
assert_code "missing file -> 1"     1 bash "$L" summary /no/such/file
assert_code "bad option -> 2"       2 bash "$L" -Q summary "$FX/access.log"
assert_code "valid run -> 0"        0 bash "$L" summary "$FX/access.log"
