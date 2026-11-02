#!/usr/bin/env bash
# Lab 4 exercise — a predicate and a producer, the two ways a function returns.
# Complete each TODO, then run:  bash ../grade.sh

# is_valid_status: a PREDICATE — return 0 (success) if "$1" is a valid HTTP
# status (three digits, first digit 1-5), non-zero otherwise.  Prints nothing.
is_valid_status() {
  local code="$1"
  # TODO: return 0 when "$code" matches ^[1-5][0-9][0-9]$, else return 1.
  return 0
}

# status_class: a PRODUCER — print the class of a status: 404 -> 4xx, 503 -> 5xx.
# Print "unknown" for anything that is not a valid status.
status_class() {
  local code="$1"
  # TODO: if is_valid_status "$code", print "${code:0:1}xx"; else print "unknown".
  printf 'FIXME\n'
}
