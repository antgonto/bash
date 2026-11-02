#!/usr/bin/env bash
# Lab 3 exercise — counting with loops and associative arrays.
# Complete each TODO, then run:  bash ../grade.sh

# count_status: tally status codes (field 9) from an access log.
# Print "<code> <count>" lines, sorted by code.
count_status() {
  local f="$1" line
  local -A n
  while IFS= read -r line; do
    # TODO: split the line into fields and take field 9 (index 8):
    #   read -ra parts <<< "$line"; code="${parts[8]:-}"
    # skip anything that is not a 3-digit code, then increment safely:
    #   n["$code"]=$(( ${n["$code"]:-0} + 1 ))
    :
  done < "$f"
  # TODO: print each "code count" line, sorted by code:
  #   for c in $(printf '%s\n' "${!n[@]}" | sort); do printf '%s %s\n' "$c" "${n[$c]}"; done
  :
}

# bruteforce_count: how many failed sshd logins came from <ip> in an auth log.
bruteforce_count() {
  local f="$1" ip="$2" line count=0
  # TODO: for each line, if it is a "Failed password ... from <ip> ..." line,
  #   increment count.  hint: [[ "$line" == *"Failed password"*"from $ip "* ]]
  printf '0\n'
}
