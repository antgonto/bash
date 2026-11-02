# shellcheck shell=bash
# assert.sh — a ~20-line test harness (no bats required). Each assert records a
# pass/fail; t_summary prints the tally and returns non-zero if anything failed.
T_PASS=0; T_FAIL=0
assert_eq() {   # assert_eq "name" "$got" "$want"
  if [[ "$2" == "$3" ]]; then (( ++T_PASS )); printf 'ok - %s\n' "$1"
  else (( ++T_FAIL )); printf 'not ok - %s (got=%q want=%q)\n' "$1" "$2" "$3"; fi
}
assert_ok() {   # assert_ok "name" cmd...   (expects exit 0)
  local n="$1"; shift
  if "$@" >/dev/null 2>&1; then (( ++T_PASS )); printf 'ok - %s\n' "$n"
  else (( ++T_FAIL )); printf 'not ok - %s\n' "$n"; fi
}
assert_code() { # assert_code "name" WANT cmd...
  local n="$1" want="$2"; shift 2; local rc
  if "$@" >/dev/null 2>&1; then rc=0; else rc=$?; fi
  if [[ "$rc" -eq "$want" ]]; then (( ++T_PASS )); printf 'ok - %s\n' "$n"
  else (( ++T_FAIL )); printf 'not ok - %s (rc=%s want=%s)\n' "$n" "$rc" "$want"; fi
}
t_summary() { printf '# %d passed, %d failed\n' "$T_PASS" "$T_FAIL"; [[ "$T_FAIL" -eq 0 ]]; }
