# shellcheck shell=bash
# Unit tests for lib/parse.sh (functions already sourced by run.sh; $FX set).
assert_eq "field_status counts 200s"     "$(field_status "$FX/access.log" | grep -c '^200$')" "85"
assert_eq "field_status counts 401s"     "$(field_status "$FX/access.log" | grep -c '^401$')" "40"
assert_eq "field_ip sees the top talker" "$(field_ip "$FX/access.log" | sort -u | grep -c '^10.0.0.1$')" "1"
assert_eq "count_col ranks 10.0.0.1 first" "$(count_col "$FX/access.log" 1 1 | awk '{print $2}')" "10.0.0.1"
assert_eq "failed_login_ips finds 25 from attacker" "$(failed_login_ips "$FX/auth.log" | grep -c '^203.0.113.9$')" "25"
assert_eq "accepted_login_count"          "$(accepted_login_count "$FX/auth.log")" "2"
assert_eq "status_classes reports 4xx=50" "$(status_classes "$FX/access.log" | awk '$1=="4xx"{print $2}')" "50"
