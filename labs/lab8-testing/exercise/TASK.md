# Lab 8 exercise — testing and quality

You write the test harness the whole course uses, in `assert.sh`.

## What you build
- `assert_eq NAME GOT WANT` — on a match, bump the global `PASSED`; on a mismatch,
  bump `FAILED` and print `FAIL <name>: got [..] want [..]`. That is the entire
  idea behind `bats` and every xUnit — compare, count, report.

## Do it
1. `bash grade.sh` — seeds `work/` and grades it (the harness must count correctly
   and pass shellcheck).
2. Edit `work/assert.sh`:
   ```bash
   assert_eq() {
     if [[ "$2" == "$3" ]]; then PASSED=$(( ${PASSED:-0} + 1 ))
     else FAILED=$(( ${FAILED:-0} + 1 )); printf 'FAIL %s: got [%s] want [%s]\n' "$1" "$2" "$3"; fi
   }
   ```
3. Re-run until `---- lab8: N passed, 0 failed ----`.

## Your deliverable
`work/assert.sh` fully green — the same harness as `logsleuth/tests/assert.sh`.
