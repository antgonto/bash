#!/usr/bin/env bash
# Lab 3 solution — counting with loops and associative arrays.

# count_status: tally status codes (field 9) from an access log.
count_status() {
  local f="$1" line code c
  local -A n
  local -a parts
  while IFS= read -r line; do
    read -ra parts <<< "$line"
    code="${parts[8]:-}"
    [[ "$code" =~ ^[0-9]{3}$ ]] || continue
    n["$code"]=$(( ${n["$code"]:-0} + 1 ))     # :-0 defaults an unset key under set -u
  done < "$f"
  for c in $(printf '%s\n' "${!n[@]}" | sort); do
    printf '%s %s\n' "$c" "${n[$c]}"
  done
}

# bruteforce_count: how many failed sshd logins came from <ip> in an auth log.
bruteforce_count() {
  local f="$1" ip="$2" line count=0
  while IFS= read -r line; do
    [[ "$line" == *"Failed password"*"from $ip "* ]] && count=$(( count + 1 ))
  done < "$f"
  printf '%s\n' "$count"
}
