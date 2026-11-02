#!/usr/bin/env bash
# Lab 8 solution — a test harness in a handful of lines: compare, count, report.
# The caller initialises PASSED=0 and FAILED=0 before using assert_eq.

assert_eq() {
  if [[ "$2" == "$3" ]]; then
    PASSED=$(( ${PASSED:-0} + 1 ))
  else
    FAILED=$(( ${FAILED:-0} + 1 ))
    printf 'FAIL %s: got [%s] want [%s]\n' "$1" "$2" "$3"
  fi
}
