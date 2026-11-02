# shellcheck shell=bash
# assert.sh — the LAB-08 harness, reused: compare, count, report.
PASSED=0; FAILED=0
assert_eq() {
  if [[ "$2" == "$3" ]]; then PASSED=$(( PASSED + 1 )); printf 'ok - %s\n' "$1"
  else FAILED=$(( FAILED + 1 )); printf 'not ok - %s: got [%s] want [%s]\n' "$1" "$2" "$3"; fi
}
assert_status() {   # assert_status NAME WANT cmd...
  local name="$1" want="$2"; shift 2; local got=0
  "$@" >/dev/null 2>&1 || got=$?
  assert_eq "$name" "$got" "$want"
}
