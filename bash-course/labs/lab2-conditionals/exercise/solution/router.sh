#!/usr/bin/env bash
# Lab 2 solution — input validation and subcommand routing with [[ ]] and case.

# validate_log: return 0 when "$1" is a readable file; else message + return 1.
validate_log() {
  local f="$1"
  if [[ -r "$f" ]]; then
    return 0
  else
    printf 'cannot read log file: %s\n' "$f" >&2
    return 1
  fi
}

# route: map a subcommand name to its kind, the way logsleuth dispatches.
route() {
  case "$1" in
    summary|top|errors) printf 'valid\n' ;;
    brute*)             printf 'brute\n' ;;
    *)                  printf 'unknown\n' ;;
  esac
}
