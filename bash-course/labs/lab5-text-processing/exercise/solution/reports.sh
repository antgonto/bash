#!/usr/bin/env bash
# Lab 5 solution — the counting pipeline and an awk filter.

# top_ips: the N most frequent client IPs (field 1), "<ip> <count>" most first.
top_ips() {
  local f="$1" n="$2"
  awk '{print $1}' "$f" | sort | uniq -c | sort -rn | head -n "$n" | awk '{print $2, $1}'
}

# count_class: how many lines have a status (field 9) starting with <digit>.
count_class() {
  local f="$1" d="$2"
  awk -v d="$d" '$9 ~ ("^" d) {c++} END{print c+0}' "$f"
}
