# M08 — Testing and quality: prove it, keep it proven
**Student Edition · curriculum v2.0.0-draft · self-paced, no fixed duration**

**Outcome LO-09.** You can prove a script is correct and keep it that way: write
a tiny assertion harness, unit-test functions by sourcing the library, black-box
test the command through its exit codes, pin behavior with deterministic
fixtures, enforce a zero-finding `shellcheck` gate, and debug with `set -x`.

**What you'll build.** `assert_eq` — the test harness the whole course runs on —
in `labs/lab8-testing/exercise/` (graded as A-09).

**Prerequisite check.** A-05 passed (M04: functions, `source`, status vs output);
A-08 recommended. You use S04.3 (predicate vs producer) and S06.5 (exit codes).

---

## Activity context for S08.1–S08.6

| Field | Value |
|---|---|
| Execution context | Inside the course container (or fallback shell), **at the course root** (`cd /course`); fixtures go in a scratch folder: `mkdir -p ~/bash-course-work/lab8 && bash seed/make_logs.sh ~/bash-course-work/lab8/fx` |
| Starting state | `bash tools-check.sh` reports ready; `shellcheck --version` works (the gate is a real check) |
| Validation status | Every expected output in S08.1–S08.6 was **observed** in the authoring environment (bash 5.2.21, shellcheck 0.11.0, Python 3.13, GNU coreutils 9.4; 2026-10-19, additions 2026-10-25/26) |

### S08.1 — A test is an assertion about an observable result
- **Purpose.** See that a test harness is a few lines: compare *got* with *want*, count, report. (SK-09)
- **Exact action.**
  ```bash
  PASSED=0; FAILED=0
  assert_eq() {
    if [[ "$2" == "$3" ]]; then PASSED=$(( PASSED + 1 ))
    else FAILED=$(( FAILED + 1 )); printf 'FAIL %s: got [%s] want [%s]\n' "$1" "$2" "$3"; fi
  }
  double() { echo $(( $1 * 2 )); }
  assert_eq "double 21" "$(double 21)" "42"
  assert_eq "double 0"  "$(double 0)"  "99"      # a deliberate miss
  printf 'passed=%d failed=%d\n' "$PASSED" "$FAILED"
  ```
- **Expected observation (observed).**
  ```text
  FAIL double 0: got [0] want [99]
  passed=1 failed=1
  ```
- **Verification.** One `FAIL` line naming the test, then `passed=1 failed=1`.
- **Recovery.** `passed=0 failed=0` → you called `assert_eq` inside `$( )` or a pipe; the counters changed in a subshell and were lost (S03.4). No `FAIL` line → the `want` for the second call is `42` — the miss is deliberate; change it back to `99`.
- **Evidence / next state.** **Why:** a test is just a command whose *got* comes from running the code and whose *want* you wrote down in advance. The two counters are the result; the `FAIL` line is the explanation. Everything `bats` or xUnit adds is convenience around this.

### S08.2 — Unit tests and black-box tests
- **Purpose.** Test functions directly (fast, precise) *and* the command as a whole (the contract users see).
- **Exact action.**
  ```bash
  export TOP_N=10 BRUTE_THRESHOLD=10                 # the library expects its config globals
  source logsleuth/lib/util.sh; source logsleuth/lib/parse.sh
  field_status ~/bash-course-work/lab8/fx/access.log | grep -c '^500$'     # unit: a library function
  accepted_login_count ~/bash-course-work/lab8/fx/auth.log                 # unit
  bash logsleuth/bin/logsleuth nope 2>/dev/null; echo "status=$?"          # black box: the CLI's contract
  bash logsleuth/bin/logsleuth summary ~/bash-course-work/lab8/fx/access.log >/dev/null; echo "status=$?"
  ```
- **Expected observation (observed).**
  ```text
  5
  2
  status=2
  status=0
  ```
- **Verification.** `5`, `2`, `status=2`, `status=0`.
- **Recovery.** `field_status: command not found` → the `source` lines did not run (you are not at the course root). `status=1` for `summary` → the fixture path is wrong (`ls ~/bash-course-work/lab8/fx`).
- **Evidence / next state.** **Why both:** a **unit test** sources the library and calls one function with known input — it pinpoints *which* function broke. A **black-box test** runs the installed command and checks its *exit code* and output — it catches what users would see (a wrong dispatcher, a broken option) even when every function is fine. `logsleuth/tests/` does both; so will yours.

### S08.3 — Fixtures, the `shellcheck` gate, and `set -x`
- **Purpose.** Make tests deterministic, make lint a gate rather than advice, and know your built-in debugger.
- **Exact action.**
  ```bash
  bash seed/make_logs.sh ~/bash-course-work/lab8/fx2 >/dev/null
  cmp ~/bash-course-work/lab8/fx/access.log ~/bash-course-work/lab8/fx2/access.log && echo "identical"
  shellcheck -x -P SCRIPTDIR logsleuth/bin/logsleuth logsleuth/lib/*.sh logsleuth/tests/*.sh; echo "shellcheck status=$?"
  printf '#!/usr/bin/env bash\necho $1\n' > ~/bash-course-work/lab8/bad.sh; shellcheck ~/bash-course-work/lab8/bad.sh; echo "status=$?"
  bash -c 'set -x; n=5; echo "$n"' 2>&1 1>/dev/null
  ```
- **Expected observation (observed).**
  ```text
  identical
  shellcheck status=0
  In …/bad.sh line 2:
  echo $1
       ^-- SC2086 (info): Double quote to prevent globbing and word splitting.
  …
  status=1
  + n=5
  + echo 5
  ```
- **Verification.** `identical`; a silent `shellcheck` with `status=0` for the project; a finding and `status=1` for `bad.sh`; two `+` lines.
- **Recovery.** `shellcheck: command not found` → install it or skip the gate lines; everything else in the module still works. The `+` lines missing → `set -x` output goes to **stderr**; the `2>&1 1>/dev/null` swaps the streams so you see only the trace.
- **Evidence / next state.** **Why:** a *fixture* generator with documented counts makes "140 requests" a stable assertion run after run. `shellcheck` returns non-zero on any finding, so `shellcheck … || exit 1` is a **gate** a build can fail on; `-x` follows `source`d files. `set -x` prints every command *after expansion*, prefixed `+` — the fastest way to see what a strict-mode script was doing when it died.

### S08.4 — Run a real suite
- **Purpose.** See the harness at project size and read its output format.
- **Exact action.**
  ```bash
  bash logsleuth/tests/run.sh | tail -3
  bash logsleuth/tests/run.sh >/dev/null; echo "suite status=$?"
  bash logsleuth/tests/run.sh | grep -c '^ok - '
  ```
- **Expected observation (observed).**
  ```text
  ok - bruteforce exits 3 when an IP is over threshold
  ok - bruteforce exits 0 when none over threshold
  # 17 passed, 0 failed
  suite status=0
  17
  ```
- **Verification.** `# 17 passed, 0 failed`, `suite status=0`, and `17` `ok` lines.
- **Recovery.** `not ok - …` lines → you modified `logsleuth/`; `git diff` or re-extract the bundle. A different total → the test files changed; the count must equal the `ok` lines.
- **Evidence / next state.** **Why this shape:** `run.sh` generates fixtures, sources the library, `source`s every `tests/test_*.sh`, and ends with a summary line *and* a non-zero exit if anything failed — the exit status is what a build consumes, the text is for people (the same two channels as M02 and M06). `tests/assert.sh` is a 20-line cousin of what you write in LAB-08.

### S08.5 — Bash wraps another interpreter
- **Purpose.** In the program, bash is the conductor and Python does the computing: thirty-five of its scripts call `python3`. Learn the three things the conductor must get right — the child's exit status, its output, and what `set -e` does when it fails. (SK-09)
- **Exact action.**
  ```bash
  cd /tmp && printf 'import json,sys\nd=json.load(open(sys.argv[1]))\nn=sum(1 for r in d.get("runs",[]) for x in r.get("results",[]) if x.get("level")=="error")\nprint(n)\nsys.exit(1 if n else 0)\n' > count_errors.py
  F=/course/program/fixtures
  python3 count_errors.py "$F/testssl.sarif"; echo "status=$?"
  n=$(python3 count_errors.py "$F/nuclei-unauth.sarif"); echo "n=$n status=$?"
  bash -c 'set -euo pipefail; python3 /tmp/count_errors.py /nope.sarif 2>/dev/null; echo "reached"'; echo "status=$?"
  bash -c 'set -euo pipefail; python3 /tmp/count_errors.py /nope.sarif 2>/dev/null || true; echo "reached"'; echo "status=$?"
  bash -c 'set -euo pipefail; n=$(python3 /tmp/count_errors.py /nope.sarif 2>/dev/null); echo "n=[$n]"'; echo "status=$?"
  python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3,12) else 1)' && echo "python ok" || echo "python too old"
  cd /course && bash program/ci/sarif_gate.sh program/fixtures/nuclei-unauth.sarif program/fixtures/testssl.sarif; echo "status=$?"
  bash program/ci/sarif_gate.sh program/fixtures/testssl.sarif; echo "status=$?"
  ```
- **Expected observation (observed, Python 3.13).**
  ```text
  0
  status=0
  n=1 status=1
  status=1
  reached
  status=0
  status=1
  python ok
  program/fixtures/nuclei-unauth.sarif: 1 error-level findings
  program/fixtures/testssl.sarif: 0 error-level findings
  CRITICAL findings: 1 → exit 1
  status=1
  program/fixtures/testssl.sarif: 0 error-level findings
  SARIF-GATE-PASS
  status=0
  ```
- **Verification.** Line 3 shows both facts at once — the captured output `1` *and* the status `1` of the assignment; the third `bash -c` prints `status=1` with no `n=[…]` line at all; the real gate ends in `exit 1` with one error-level finding and `SARIF-GATE-PASS` without.
- **Recovery.** `python too old` → your Python predates 3.12; the course container does not need Python, but Course 2's `ready-check.sh` runs this exact test and will say the same. A Python traceback where `status=1` is expected → you dropped `2>/dev/null`; the status is still 1, the noise is the only difference. `n=[]` printed in the third `bash -c` → you removed `-e`; without it the failed substitution assigns an empty string and the script carries on with bad data.
- **Evidence / next state.** **Three rules for wrapping a child process.** (1) *Its exit status is the assignment's status:* `n=$(python3 …)` succeeds or fails with the child, so under `set -e` a crashing child stops the script *before* `n` is used — the third `bash -c` never printed `n=[]`. (2) *Decide failure explicitly where the child's non-zero is a finding, not a bug:* `|| true` says "I expect this to fail sometimes and I will judge later" — `ci/validate_unauth.sh` does it for every scanner and judges once at the end with its `sarif_gate` (M07). (3) *Keep the contract in the child:* `count_errors.py` prints a number **and** exits 1 when it is non-zero, so bash can use it either as data (`n=$(…)`) or as a test (`if python3 …`), exactly like `jq -e`. **The program's own line:** `program/ci/sarif_gate.sh` is this step as shipped — a `for f in "$@"` loop, `n=$(python3 -c "…" "$f")`, a running total, and `[ "$total" -eq 0 ] && echo "SARIF-GATE-PASS" || { …; exit 1; }`. It does in Python what S05.6 did with `jq`; both are right, and the program uses both. When the Python is more than a line, Course 2 writes it as a here-document — `python3 - <<'EOF' … EOF` (S05.7) — eleven times across Labs 1.1, 1.2, 6.1, 6.2, 7.2, 12.1 and 12.2; the same three rules apply, with the program on stdin instead of in `-c`.

### S08.6 — Prove a file is intact: `sha256sum`, `-c`, and one corrupted byte
- **Purpose.** Course 2 Lab 6.1 and exercise 13 ("one byte refused") protect the trained model the same way: record its hash, verify the hash before loading, and *prove the check works* by corrupting a single byte and watching the load be denied. Learn the three commands that proof needs — `sha256sum`, `sha256sum -c`, and `dd … conv=notrunc` — and `tee`, which the labs use to keep a copy of what a pipeline printed. (SK-09)
- **Exact action.**
  ```bash
  cd /tmp && rm -rf integ && mkdir integ && cd integ
  printf 'weights-v1\n' > model.bin
  sha256sum model.bin > model.sha256; cat model.sha256
  sha256sum -c model.sha256; echo "status=$?"
  cp model.bin good.bin
  printf '\x00' | dd of=model.bin bs=1 seek=3 conv=notrunc 2>/dev/null
  cmp good.bin model.bin; echo "status=$?"
  sha256sum -c model.sha256; echo "status=$?"
  sha256sum -c --quiet model.sha256 2>/dev/null || echo "LOAD-DENIED"
  cp good.bin model.bin
  sha256sum -c --quiet model.sha256 && echo "LOAD-ALLOWED"
  wc -c model.bin
  printf 'a\nb\n' | tee copy.txt | wc -l; wc -l < copy.txt
  ```
- **Expected observation (observed, GNU coreutils 9.4).**
  ```text
  188cc7915669e5b8e02e419aef15f1f05974df8fb84124d4e1366025b4a38110  model.bin
  model.bin: OK
  status=0
  good.bin model.bin differ: char 4, line 1
  status=1
  model.bin: FAILED
  sha256sum: WARNING: 1 computed checksum did NOT match
  status=1
  model.bin: FAILED
  LOAD-DENIED
  LOAD-ALLOWED
  11 model.bin
  2
  2
  ```
- **Verification.** The hash line has two spaces between the digest and the name — that is the format `-c` reads back. After the `dd`, `cmp` names the exact byte (`char 4` = `seek=3`, counting from zero), the file is still 11 bytes (`conv=notrunc` *overwrote* one byte instead of truncating the file), and `-c` reports `FAILED` with status 1; restoring the copy makes it `OK` again. The last two lines are both `2`: `tee` passed the lines on *and* wrote them to `copy.txt`.
- **Recovery.** `sha256sum: command not found` on a Mac → the GNU tools step in the Environment page (section 3 step 6) was skipped; Course 2 needs the same step. `model.bin` becomes 4 bytes → you dropped `conv=notrunc`, and `dd` truncated the file at the write position; restore it from `good.bin`. The `--quiet` run still prints `model.bin: FAILED` — that is correct: `--quiet` silences `OK` lines only, failures are always reported.
- **Evidence / next state.** **The proof pattern.** A control you have only seen pass is not proven; Course 2's rule is *red then green* — make the check fail on purpose, then make it pass. `dd of=FILE bs=1 seek=N conv=notrunc` is the smallest possible sabotage: one byte at offset N, nothing else touched, which is why Lab 6.1 uses it rather than editing the model in an editor (which would rewrite the whole file). `sha256sum -c` is the check itself: it reads `DIGEST  NAME` lines, recomputes each digest and exits non-zero when *any* line fails — so it belongs on a `&&` chain or under `set -e` exactly like `jq -e` (S05.6) and `python3` (S08.5). **The program's own lines:** Lab 6.1 ships `sha256sum model/model.safetensors > model/model.sha256` next to the model and loads it only after `sha256sum -c model/model.sha256 && echo LOAD-ALLOWED`; exercise 13's sabotage is `printf '\x00' | dd of=model/model.safetensors bs=1 seek=100 conv=notrunc` — your line 6 with a different offset. `tee` appears wherever a lab wants the terminal *and* a file: `for n in 100 500 2000 5000; do python extract.py $n; done | tee fidelity.txt` (Lab 12.2) and `… | tee robot.json | jq '{name, secret}'` (Lab 9.1) — a pipeline can branch once, into a file, without losing its stdout. The digest in `model.sha256` is the same object Chapter 8 signs with `cosign`; the hash proves *integrity*, the signature proves *who* vouched for it.

---

## Worked demonstration (10 min)

```bash
cd /course
bash labs/lab8-testing/lab.sh
```
**Expected observation (observed).** `---- lab8: 14 passed, 0 failed ----`. It builds
a demo harness and counts one pass and one deliberate fail; unit-tests
`field_status` (5 lines of `500`) and `accepted_login_count` (2); black-box
tests `logsleuth -V`, an unknown command → 2, a good run → 0; proves the fixture
is always 140 lines; shows `set -x` output; then runs the project's own suite
(`0 failed`, the `ok` count equals the reported passes, exit 0) and the
whole-project `shellcheck` gate with zero findings.

---

## LAB-08 — Your exercise (graded as A-09) — 45 min

| Field | Value |
|---|---|
| Location | `labs/lab8-testing/exercise/` (read `TASK.md`) |
| Starting assets | `starter/assert.sh` (`assert_eq` with the body as a `# TODO`), `grade.sh` |
| Allowed resources | This module, documentation, AI assistance (disclosed); **not** `solution/` |
| Deliverables | `work/assert.sh` passing the grader; `work/REFLECTION.md` with R1 and R2 |
| Acceptance | `bash grade.sh` ends `---- lab8: 4 passed, 0 failed ----`; both reflections present |

**Procedure.**
1. `cd labs/lab8-testing/exercise && bash grade.sh`. **Observed on the starter:** `---- lab8: 1 passed, 3 failed ----` (the empty function is already shellcheck-clean).
2. Edit `work/assert.sh`: `assert_eq NAME GOT WANT` — on a match increment the global `PASSED`; on a mismatch increment `FAILED` and print `FAIL <name>: got [..] want [..]` (S08.1). Use `${PASSED:-0}` so the harness also works when a caller forgot to initialize.
3. Re-run until **`---- lab8: 4 passed, 0 failed ----`** (observed with the reference). The checks: two matches count `PASSED=2`; one deliberate miss counts `FAILED=1`; the miss prints `got [0] want [99]`; shellcheck-clean.
4. `work/REFLECTION.md`:
   - **R1.** The grader calls `assert_eq … >/dev/null` for the deliberate miss and still sees `FAILED=1`, but a call inside `$( )` would not change the counters. Explain where a test's *result* lives in this harness and why that place matters.
   - **R2.** `logsleuth`'s suite tests `field_status` directly **and** runs `bin/logsleuth nope` expecting status 2. Name one bug only the black-box test would catch and one only the unit test would pinpoint.

**Learner-visible rubric (A-09).** *Pass* = `0 failed` **and** both reflections name the mechanism. Unlimited attempts.

**Hints.** H1: the whole function is one `if … else … fi`. H2: `PASSED=$(( ${PASSED:-0} + 1 ))` — arithmetic, not string concatenation. H3: the message format is checked literally: `got [0] want [99]`.

**Reset.** `rm -rf work && bash grade.sh`.

---

## Knowledge checks (predict, then run)

1. In `assert_eq "double 21" "$(double 21)" "42"`, which argument is *got* and which is *want*, and why does the order matter?
2. Why do generated fixtures make a test deterministic?
3. What does `shellcheck -x` add?
4. Where does `set -x` write its trace, and what does each line show?
5. The suite prints `# 17 passed, 0 failed` and exits 0. Which of the two should a build gate on?
6. `sha256sum -c model.sha256` prints `model.bin: OK` for a file you then overwrite with `printf 'weights-v1\n' > model.bin` — the same eleven bytes as before. What does `-c` say now, and what would it say if the file had been rewritten with the same content but by `dd … conv=notrunc`?

---

## In the SecMLOps Program
Course 2's `ci/gates.sh` is a gate chain in your harness's spirit — `ruff`, `mypy`, `pytest -q`, Opengrep with `--error`, Trivy with `--exit-code 1`, Gitleaks — each tool's exit status *is* the assertion, and the script's own `set -e` makes the first failure the result. `tests/smoke/test_api.py` is the black-box test `ci/deploy.sh` runs after every rollout; `stackctl`'s `tests/run.sh` in M09 is the unit side. Course 1's `make lint` is the same idea for YAML and Ansible (`yamllint`, `ansible-lint`); the shellcheck gate you learned is the one its `scripts/*.sh` do not yet have — a fair first contribution when you get there.

**Read the real thing (5 min).** Open `program/ci/sarif_gate.sh` and `program/scripts/ready-check.sh` (the Course 2 baseline's "is my computer ready?"). In `notes/M08-read.txt`: (a) in `sarif_gate.sh`, what is the one line that would be wrong under `set -e` if a SARIF file were malformed, and what happens today; (b) `ready-check.sh` uses `set -u` without `-e` — find two lines that *depend* on that choice. Answers at the end of the page.

---

## Recap and transfer
Compare, count, report; unit tests for functions, black-box tests for the
command; fixtures for determinism; `shellcheck` as a gate; `set -x` to see.
**Transfer:** A-10 asks for a tool that passes a 12-check rubric built with this
harness; M09's `stackctl` ships a `tests/` directory whose **mock driver** proves
the control logic (validate → plan → apply, confirmation-gated destroy) without a
Docker daemon — the same assertions, a different subject.

---

## Self-check answers

1. `"$(double 21)"` is *got* (what the code produced), `"42"` is *want* (what you decided in advance); swapping them makes the `FAIL` message lie about which side is wrong.
2. The generator writes the same lines with the same documented counts every time (observed: two runs `identical`), so an assertion like "140 requests" cannot flake.
3. It follows `source`d files, so library code is linted along with the script that includes it.
4. To **stderr**; each line is one command *after expansion*, prefixed with `+` (observed: `+ n=5`, `+ echo 5`).
5. The exit status — text is for people; a build that greps for `0 failed` breaks the day someone rewords the summary.
6. `OK` both times — a hash is a function of the *bytes*, not of how or when they were written, so any rewrite that reproduces the same bytes verifies; that is also why one changed byte anywhere (S08.6) is enough to fail it.

**Read the real thing.** (a) `n=$(python3 -c "…" "$f")` — a malformed file makes Python raise, the substitution fails, and under `set -euo pipefail` the script aborts with Python's traceback on stderr and status 1 before the total is printed. That is acceptable for a gate (a report it cannot read must not pass), but the message is a traceback, not `CRITICAL …`; a `|| { echo "unreadable: $f"; exit 1; }` would say so. (b) `command -v cosign >/dev/null && ok … || warnf …` and the `curl -s --max-time 4 … || warnf …` lab check: both rely on a failing command *continuing* the script so the `WARN` line can be printed and the final `RESULT:` line computed — under `-e` the first missing tool would end the script. `set -u` still protects the `$fail`/`$warn` counters from a typo.
