# shellcheck shell=bash
# Unit tests for lib/report.sh.
# BRUTE_THRESHOLD is read by cmd_bruteforce (sourced from report.sh):
# shellcheck disable=SC2034
assert_eq "summary requests=140"  "$(cmd_summary "$FX/access.log" | awk '/requests/{print $2}')" "140"
assert_eq "summary unique IPs=4"  "$(cmd_summary "$FX/access.log" | awk '/unique/{print $3}')" "4"
assert_eq "errors reports 5xx=5"  "$(cmd_errors "$FX/access.log" | awk 'NR==1{print $3}')" "5xx=5"
assert_code "bruteforce exits 3 when an IP is over threshold" 3 cmd_bruteforce "$FX/auth.log"
BRUTE_THRESHOLD=999
assert_code "bruteforce exits 0 when none over threshold" 0 cmd_bruteforce "$FX/auth.log"
BRUTE_THRESHOLD=10
