# Part 8 — Testing and quality

> Graded by `labs/lab8-testing/exercise/grade.sh`. Proving a script is correct and
> keeping it that way. In this part you write the test harness the whole course
> uses — a few lines that compare, count, and report.

**What you'll build.** In `labs/lab8-testing/exercise/` you implement `assert_eq`
in `assert.sh`. First, the moves.

---

## Step 1 — A test is an assertion about an observable result

The whole harness is "compare got vs want, count failures":

```bash
PASSED=0; FAILED=0
assert_eq() {
  if [[ "$2" == "$3" ]]; then PASSED=$(( PASSED + 1 ))
  else FAILED=$(( FAILED + 1 )); printf 'FAIL %s: got [%s] want [%s]\n' "$1" "$2" "$3"; fi
}
double() { echo $(( $1 * 2 )); }
assert_eq "double 21" "$(double 21)" "42"
assert_eq "double 0"  "$(double 0)"  "99"     # a deliberate miss
printf 'passed=%d failed=%d\n' "$PASSED" "$FAILED"
```
```text
FAIL double 0: got [0] want [99]
passed=1 failed=1
```

`bats` is a fuller framework if you want it, but you don't need it to start.

---

## Step 2 — Unit-test the functions; black-box-test the CLI

- **Unit tests** source the library and call functions directly (`field_status`,
  `accepted_login_count`) — fast and precise.
- **Black-box tests** run the built command and check its **exit code** — the
  CLI's contract: unknown command → 2, missing file → 1, good run → 0.

logsleuth's suite does both; so should yours.

---

## Step 3 — Fixtures, a lint gate, and `set -x`

- **Fixtures** make tests deterministic: `seed/make_logs.sh` writes logs with
  *exact* documented counts, so "140 requests" is a stable assertion.
- **shellcheck as a gate**: the build fails on any finding. The whole logsleuth
  tree passes with zero.
- **`set -x`** prints every command as it runs when you need to debug:

```bash
bash -c 'set -x; n=5; echo "$n"' 2>&1 1>/dev/null
```
```text
+ n=5
+ echo 5
```

---

## Your exercise

Open `labs/lab8-testing/exercise/` and read `TASK.md`. You implement `assert_eq`
so it bumps `PASSED` on a match and `FAILED` (plus a message) on a mismatch, and
passes shellcheck.

```bash
cd labs/lab8-testing/exercise
bash grade.sh                 # seeds work/ and grades it
# ...edit work/assert.sh...
bash grade.sh                 # until: ---- lab8: N passed, 0 failed ----
```

---

## What you can do at the end of Part 8

Write a test harness, test both functions and the CLI, pin behavior with fixtures,
enforce a shellcheck gate, and debug with `set -x`. The harness you wrote is the
same one in `logsleuth/tests/assert.sh` — your scripts are now not just working but
*provably* working, and they stay that way.
