# shellcheck shell=bash
# parse.sh — field extraction for the Combined Log Format and sshd auth lines.
#
# A log line is untrusted text. These helpers each read a file path and emit one
# value per line, so they compose in pipelines. They favour awk for the columnar
# access log (fast, idiomatic) and pure bash where it is clearer.

# Combined Log Format, whitespace-split:
#   $1 client-ip   $7 request-path   $9 status   $10 bytes
# (the fixtures have space-free paths; parse_status validates the field so a
#  malformed line is skipped rather than miscounted.)
field_ip()     { awk '{print $1}' "$1"; }
field_path()   { awk '$9 ~ /^[0-9]{3}$/ {print $7}' "$1"; }
field_status() { awk '$9 ~ /^[0-9]{3}$/ {print $9}' "$1"; }

# status class: 2xx/3xx/4xx/5xx counts, printed as "<class> <count>"
status_classes() {
  awk '$9 ~ /^[0-9]{3}$/ { cls[substr($9,1,1) "xx"]++ }
       END { for (c in cls) print c, cls[c] }' "$1" | sort
}

# count a column and print "count value", most frequent first
count_col() {   # count_col <file> <awk-col> [limit]
  local file="$1" col="$2" limit="${3:-0}"
  awk -v c="$col" '$9 ~ /^[0-9]{3}$/ {print $c}' "$file" | sort | uniq -c | sort -rn \
    | { if [[ "$limit" -gt 0 ]]; then head -n "$limit"; else cat; fi; }
}

# sshd auth log: emit the source IP of every failed password attempt
failed_login_ips() {
  # "... Failed password for [invalid user] NAME from IP port N ssh2"
  grep -F 'Failed password' "$1" | sed -E 's/.* from ([0-9.]+) port .*/\1/'
}
accepted_login_count() { grep -cF 'Accepted password' "$1"; }
