#!/usr/bin/env bash
# Lab 1 exercise — parameter-expansion helpers (the exact moves logsleuth uses).
# Complete each TODO, then run:  bash ../grade.sh   (it grades your work/ copy).
#
# These are sourced by the grader, so they only need to DEFINE the functions.

# stem: /var/log/nginx/access.log -> access   (basename, then drop a .log suffix)
stem() {
  local path="$1"
  # TODO: print the basename of "$path" with any ".log" suffix removed.
  #   hint: ${path##*/} is the basename; ${base%.log} drops a trailing .log
  printf '%s\n' "FIXME"
}

# report_name: compose  report-<stem>-<date>.txt
report_name() {
  local path="$1" date="$2"
  # TODO: print  report-<stem>-<date>.txt  using stem() above.
  printf '%s\n' "FIXME"
}

# parse_kv: "top_n = 25"  ->  set globals KEY=top_n and VALUE=25 (trimmed)
parse_kv() {
  local line="$1"
  # TODO: split "$line" on '=' with  IFS='=' read -r k v,  then trim each side.
  #   hint: a bare  read -r KEY <<< "$k"  strips surrounding whitespace for free.
  KEY="FIXME"; VALUE="FIXME"
}
