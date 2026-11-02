#!/usr/bin/env bash
# Lab 3 — Loops and arrays. The right way to read a file line by line, indexed
# arrays, and ASSOCIATIVE arrays for counting — which is exactly how logsleuth
# finds brute-force source IPs. Project milestone: you build the counter, then
# confirm the tool agrees.
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/../_lib.sh"
W="$(lab_workdir lab3)"; cd "$W" || exit 1; make_fixtures "$W/fx"

echo "== for: over a list, over an array, and C-style =="
sum=0; for n in 1 2 3 4; do (( sum += n )); done
is_eq "for over a list"   "$sum" "10"
out=""; for ((i=0; i<3; i++)); do out+="$i"; done
is_eq "C-style for"       "$out" "012"

echo "== while read -r is the ONLY correct way to read lines =="
# -r keeps backslashes literal; IFS= keeps leading/trailing spaces; quoting the
# var keeps the line intact. Count lines in access.log by hand.
count=0
while IFS= read -r _line; do (( ++count )); done < "$W/fx/access.log"
is_eq "while read -r counted every line" "$count" "140"
# WHY -r: without it, a backslash is eaten
raw="$(printf 'a\\tb' | { IFS= read -r x; printf '%s' "$x"; })"
is_eq "read -r preserves the backslash" "$raw" 'a\tb'

echo "== until / break / continue =="
i=0; until (( i >= 3 )); do (( ++i )); done; is_eq "until stops at the condition" "$i" "3"
seen=""; for c in a skip b skip c; do [[ "$c" == skip ]] && continue; seen+="$c"; done
is_eq "continue skips an iteration" "$seen" "abc"

echo "== indexed arrays =="
declare -a ips=( 10.0.0.1 10.0.0.2 203.0.113.9 )
is_eq "length \${#arr[@]}"       "${#ips[@]}" "3"
is_eq "index 0"                  "${ips[0]}" "10.0.0.1"
ips+=( 198.51.100.7 )            # append
is_eq "append grows the array"   "${#ips[@]}" "4"
is_eq "iterate + join"           "$(printf '%s,' "${ips[@]}")" "10.0.0.1,10.0.0.2,203.0.113.9,198.51.100.7,"

echo "== mapfile reads a whole file into an array in one shot =="
mapfile -t lines < "$W/fx/auth.log"
is_eq "mapfile line count matches wc" "${#lines[@]}" "$(wc -l < "$W/fx/auth.log")"

echo "== ASSOCIATIVE arrays: counting, the core skill for log analysis =="
declare -A status_count
while read -r code; do
  [[ "$code" =~ ^[0-9]{3}$ ]] || continue
  status_count["$code"]=$(( ${status_count["$code"]:-0} + 1 ))   # :-0 for set -u safety
done < <(awk '{print $9}' "$W/fx/access.log")
is_eq "counted 200s" "${status_count[200]}" "85"
is_eq "counted 401s" "${status_count[401]}" "40"
is_eq "counted 500s" "${status_count[500]}" "5"
is_eq "number of distinct statuses (keys)" "${#status_count[@]}" "4"

echo "== build the brute-force counter yourself, then check logsleuth agrees =="
declare -A fails
while read -r line; do
  [[ "$line" == *"Failed password"* ]] || continue
  ip="${line##*from }"; ip="${ip%% *}"           # extract 'from <IP> port'
  fails["$ip"]=$(( ${fails["$ip"]:-0} + 1 ))
done < "$W/fx/auth.log"
is_eq "your counter: 203.0.113.9 failed 25x" "${fails[203.0.113.9]}" "25"
is_eq "your counter: 198.51.100.23 failed 4x" "${fails[198.51.100.23]}" "4"
# the tool uses this very algorithm; its report must name the same top offender
contains "logsleuth bruteforce flags 203.0.113.9 with 25" \
  "$(logsleuth bruteforce "$W/fx/auth.log")" "203.0.113.9"
contains "logsleuth bruteforce prints the count 25" \
  "$(logsleuth bruteforce "$W/fx/auth.log")" "25 failed"
check "logsleuth exits 3 when an IP is over threshold (pipeline-friendly)" \
  bash -c 'logsleuth bruteforce "$1" >/dev/null; [ $? -eq 3 ]' _ "$W/fx/auth.log"

summary lab3
