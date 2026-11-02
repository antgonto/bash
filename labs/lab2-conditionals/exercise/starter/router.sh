#!/usr/bin/env bash
# Lab 2 exercise — input validation and subcommand routing.
# Complete each TODO, then run:  bash ../grade.sh

# validate_log: succeed (return 0) when "$1" is a readable file; otherwise print
# a clear message to stderr and return 1.  (logsleuth guards every log this way.)
validate_log() {
  local f="$1"
  # TODO: if "$f" is readable ([[ -r "$f" ]]) return 0; else print
  #   "cannot read log file: $f"  to stderr (>&2) and return 1.
  return 0
}

# route: map a subcommand name to its kind, the way logsleuth dispatches.
route() {
  # TODO: case "$1" in
  #   summary|top|errors) echo valid ;;
  #   brute*)             echo brute ;;
  #   *)                  echo unknown ;;
  # esac
  printf 'FIXME\n'
}
