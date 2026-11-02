#!/usr/bin/env bash
# Lab 4 solution — a predicate (status) and a producer (stdout).

# is_valid_status: PREDICATE — 0 if "$1" is a 1xx-5xx three-digit code.
is_valid_status() {
  local code="$1"
  [[ "$code" =~ ^[1-5][0-9][0-9]$ ]]
}

# status_class: PRODUCER — print "<n>xx", or "unknown" for an invalid code.
status_class() {
  local code="$1"
  if is_valid_status "$code"; then
    printf '%sxx\n' "${code:0:1}"
  else
    printf 'unknown\n'
  fi
}
