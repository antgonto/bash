#!/usr/bin/env bash
# Lab 1 solution — parameter-expansion helpers, the exact moves logsleuth uses.

# stem: /var/log/nginx/access.log -> access   (basename, then drop a .log suffix)
stem() {
  local path="$1" base
  base="${path##*/}"              # strip everything up to the last '/'
  printf '%s\n' "${base%.log}"    # strip a trailing '.log'
}

# report_name: compose  report-<stem>-<date>.txt
report_name() {
  local path="$1" date="$2"
  printf 'report-%s-%s.txt\n' "$(stem "$path")" "$date"
}

# parse_kv: "top_n = 25"  ->  set globals KEY=top_n and VALUE=25 (trimmed)
parse_kv() {
  local line="$1" k v
  IFS='=' read -r k v <<< "$line"
  read -r KEY   <<< "$k"          # a bare read trims surrounding whitespace
  read -r VALUE <<< "$v"
}
