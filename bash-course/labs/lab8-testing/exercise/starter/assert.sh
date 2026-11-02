#!/usr/bin/env bash
# Lab 8 exercise — the smallest useful test harness.
# Complete the TODO, then run:  bash ../grade.sh
#
# assert_eq NAME GOT WANT:
#   - on a match: increment the global PASSED
#   - on a mismatch: increment the global FAILED and print "FAIL <name>: ..."
# The caller initialises PASSED=0 and FAILED=0 before using it.

assert_eq() {
  # TODO: if [[ "$2" == "$3" ]]; then PASSED=$(( ${PASSED:-0} + 1 ))
  #       else FAILED=$(( ${FAILED:-0} + 1 )); printf 'FAIL %s: got [%s] want [%s]\n' "$1" "$2" "$3"; fi
  :
}
