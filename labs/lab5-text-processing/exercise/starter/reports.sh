#!/usr/bin/env bash
# Lab 5 exercise — the counting pipeline and an awk filter.
# Complete each TODO, then run:  bash ../grade.sh

# top_ips: the N most frequent client IPs (field 1) in an access log.
# Print "<ip> <count>" lines, most frequent first.
top_ips() {
  local f="$1" n="$2"
  # TODO: the canonical pipeline:
  #   awk '{print $1}' "$f" | sort | uniq -c | sort -rn | head -n "$n" | awk '{print $2, $1}'
  :
}

# count_class: how many lines have a status (field 9) starting with <digit>.
# count_class access.log 4  ->  the number of 4xx responses.
count_class() {
  local f="$1" d="$2"
  # TODO: awk -v d="$d" '$9 ~ ("^" d) {c++} END{print c+0}' "$f"
  printf '0\n'
}
