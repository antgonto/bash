# M08 — Testing and quality: prove it, keep it proven
**FULL TRAINER EDITION · curriculum v2.0.0-draft · self-paced, no fixed duration**

> **TRAINER ONLY — about this edition.** Student text verbatim; trainer blocks inserted. IDs: S08.1–S08.4, LAB-08, A-09.
>
> **Prep (≈15 min).** `cd labs/lab8-testing/exercise && rm -rf work && bash grade.sh` → **observed** `---- lab8: 1 passed, 3 failed ----`; `GRADE_TARGET="$PWD/solution" bash grade.sh` → **observed** `---- lab8: 4 passed, 0 failed ----`; `bash labs/lab8-testing/lab.sh` → **observed** `---- lab8: 14 passed, 0 failed ----`; `bash logsleuth/tests/run.sh` → **observed** `# 17 passed, 0 failed`, exit 0; `shellcheck -x -P SCRIPTDIR logsleuth/bin/logsleuth logsleuth/lib/*.sh logsleuth/tests/*.sh` → silent, exit 0. Without `shellcheck` installed the grader's last check is a *skipped PASS* — certify A-09 only where shellcheck exists.
>
> **Trainer effort:** prep 15 min; A-09 review ≈ 5 min per learner. This module closes the core sequence: after A-09 a learner is eligible for **A-10** (the integrative practical, separate page).
>
> **Facilitator pathway (optional 40-min session).** 0–8 min: S08.1 live — write the harness from memory in front of the room, including the deliberate miss. 8–18 min: S08.2–S08.3 self-paced; circulate on "where do the counters live". 18–35 min: LAB-08. 35–40 min: debrief R2 with the two bug examples below.


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


> **TRAINER ONLY.** *Ask:* "Where is the test result stored?" *Expected:* "in the two global counters — the `FAIL` line is only the explanation." *Observed, the trap this sets up:* `out="$(assert_eq x 1 2)"` captures the message but leaves `FAILED` unchanged (`0`), while a direct call with `>/dev/null` increments it — the grader's third check is written exactly that way (`out="$(PASSED=0; FAILED=0; assert_eq …)"`) *so that* it can read the message without disturbing the counters. This is R1. *Misconception:* a harness needs a framework — `logsleuth/tests/assert.sh` is twenty lines and the course's own graders are the same idea.

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


> **TRAINER ONLY.** *Two bugs to use in the debrief (R2):* (a) swap the `summary` and `top` branches in the `case` dispatcher — every unit test stays green, only a black-box test notices; (b) make `field_status` match `$8` instead of `$9` — the black-box `summary` test fails too, but only the unit test tells you *which* function. *Why the `export TOP_N=10 BRUTE_THRESHOLD=10` line:* the library reads config globals that `bin/logsleuth` normally sets after `load_config`; sourcing the library "naked" needs them (under `set -u` their absence would abort). *Observed:* `field_status … | grep -c '^500$'` → `5`; `accepted_login_count` → `2`.

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


> **TRAINER ONLY.** *Ask:* "What is the difference between `shellcheck` as advice and as a gate?" *Expected:* "the exit status — a gate fails the build on any finding." *Observed:* the project is silent with status 0; `bad.sh` with an unquoted `$1` reports `SC2086 (info)` and **status 1** — even an *info*-level finding fails the gate, which is deliberate for this course (the SC2086 message is the quoting rule from M01 restated by a machine). *`-P SCRIPTDIR`:* tells shellcheck where to resolve `source` paths relative to the script, so the `# shellcheck source=` directives in `bin/logsleuth` work from any cwd. *`set -x` tip:* learners who want it only for a region can `set -x; …; set +x`; `bash -x script` traces the whole run.

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


> **TRAINER ONLY.** *Ask:* "Why does `run.sh` print `# 17 passed, 0 failed` with a leading `#`?" *Expected:* "it is TAP-flavored — `ok`/`not ok` per test, comments for summaries — so standard TAP consumers can read it." *Observed:* the `ok -` count (17) equals the reported passes, which `lab.sh` verifies. *Preview for A-10:* the rubric grader (`labs/capstone/exercise/grade.sh`) uses the same assertion shape (`is_eq`, `check`, `denies`); learners who can read `run.sh` can read their own grader's failures.

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


> **TRAINER ONLY (added Batch 6, 2026-10-25; outputs observed, Python 3.13, bash 5.2).** *Why this step exists:* 35 of the program's scripts call `python3`; Course 2's `ci/` is bash orchestrating Python, and the course had never shown a child process's status flowing back into bash. *Ask:* "After `n=$(python3 …)`, whose exit status is `$?`?" *Expected:* "the child's — an assignment with a substitution takes the substitution's status; that is why line 3 prints `n=1 status=1`." *The one line to make them watch:* the third `bash -c` prints **only** `status=1` — no `n=[]` — because `set -e` aborted on the failed substitution before `echo`. Remove `-e` live and `n=[]` appears: the script would have continued with empty data. *Bridge to M07:* `|| true` is the deliberate version of that — `validate_unauth.sh` uses it per scanner and judges once at the end; S08.5 rule 2. *On `sarif_gate.sh`:* it is the Python twin of S05.6's `jq -e`; ask which they would choose and accept either with a reason (`jq`: no interpreter dependency, one-liner; Python: already present for the project, easier to extend). *Reading-exercise trap:* (a) asks for the line that is fragile to a malformed SARIF — `n=$(python3 -c …)`; a learner who answers "the `for` loop" has not traced the status. *Grading relevance:* none — the reading answers are the evidence; A-09's grader is unchanged.

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


> **TRAINER ONLY (added Batch 7 follow-up, 2026-10-26; outputs observed, GNU coreutils 9.4).** *Why this step exists:* Course 2 Lab 6.1 ("ModelScan, safetensors & signed model artifacts") and exercise 13 ("one byte refused") both hinge on `sha256sum -c` plus a one-byte `dd` sabotage, and `tee` recurs in Labs 9.1 and 12.2; none of the three had been taught. *Demo move:* run the sabotage line, then ask the room what `wc -c` will print *before* running it — most predict a shrunken file; `conv=notrunc` is the point. *Ask:* "Why `dd` and not an editor?" *Expected:* an editor rewrites every byte and may change line endings or trailing newline; `dd` changes exactly the byte you name, so the test proves the hash is sensitive to *one* byte. *Pitfall:* learners run `sha256sum -c` from another directory and get `No such file or directory` — the checksum file stores the *name as written*, relative to where `sha256sum` ran. *Pitfall 2:* on a Mac without the GNU tools, `shasum -a 256` exists but `sha256sum` does not — point at Environment section 3 step 6 rather than teaching the alternative. *Knowledge check 6* is the one most get wrong: they expect "written by a different tool" to matter; the answer is in the Evidence paragraph (a hash is a function of the bytes).

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


> **TRAINER ONLY — what `lab.sh` asserts (14 checks, observed).** Demo harness counts one pass and one fail (it uses `dP`/`dF` so it cannot clobber the lab's own counters — a nice aside on namespacing globals); unit: `field_status` 500s = 5, `accepted_login_count` = 2; black box: `-V`, unknown command → 2, good run → 0; fixture is always 140 lines; `set -x` shows `+ n=5` and `+ echo 5`; the project suite reports `0 failed`, its `ok` count equals its reported passes, it exits 0, and the whole-project shellcheck gate is silent.

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


> **TRAINER ONLY — complete solution (reference `solution/assert.sh`, observed 4/4):**
> ```bash
> #!/usr/bin/env bash
> # Lab 8 solution — a test harness in a handful of lines: compare, count, report.
> # The caller initialises PASSED=0 and FAILED=0 before using assert_eq.
>
> assert_eq() {
>   if [[ "$2" == "$3" ]]; then
>     PASSED=$(( ${PASSED:-0} + 1 ))
>   else
>     FAILED=$(( ${FAILED:-0} + 1 ))
>     printf 'FAIL %s: got [%s] want [%s]\n' "$1" "$2" "$3"
>   fi
> }
> ```
> *Acceptable variations:* `(( ++PASSED ))` (passes; note it needs an initialized counter and would abort under `set -u` if the caller forgot — the `${PASSED:-0}` form is the robust one); `echo` instead of `printf` (passes if the text is identical); `[ "$2" = "$3" ]` (passes; quoted, so safe). A version that prints `PASS` lines on success **passes the grader** (stdout of the two matches is not inspected) but is noisier than the course's convention — accept, mention. A version declaring `local PASSED` **fails** (counters never reach the caller) — the M04 scope lesson again.
>
> **Grading procedure (≈5 min/learner).** 1) `GRADE_TARGET=/path/to/their/work bash labs/lab8-testing/exercise/grade.sh` → require `---- lab8: 4 passed, 0 failed ----`. 2) Reflections:
> - **R1 — Met:** results live in the global counters `PASSED`/`FAILED`; a function called inside `$( )` runs in a subshell whose variable changes are discarded, while `>/dev/null` only redirects output and leaves the shell — and thus the counters — intact. **Strong:** connects it to M03's piped-`while` subshell or to the grader's own `out="$( … )"` trick, or notes that printing the counts to stdout instead would force callers to parse text. **Not met:** "the message goes to /dev/null but the variable stays" without naming the subshell.
> - **R2 — Met:** a black-box test catches wiring/dispatch/option bugs (wrong `case` branch, broken `getopts`, wrong exit code) that unit tests of correct functions never see; a unit test pinpoints *which* function misbehaves (e.g., `field_status` reading field 8) where the black-box test only reports a wrong summary. **Strong:** gives a concrete bug for each side (the two above or equivalents). **Not met:** "black-box tests the whole thing, unit tests the parts" with no bug named.
>
> 3) Record `A-09 PASS` only with 4/4 and both reflections ≥ Met.
>
> **Calibration.** *R1 Met:* "The counters are globals; `$( )` runs the function in a subshell, so its `FAILED=1` happens in a copy that disappears. `>/dev/null` just throws away the text, the function still runs in my shell, so the real `FAILED` changes." *R1 Not met:* "Because the grader redirects output and the variables are separate from output." (describes, no mechanism).
>
> **Model feedback (Not yet):** "`counted two passes` got `unset`: your function assigns `passed` (lower case) — the grader reads `PASSED`." **Remediation:** S08.1. **Equivalent reassessment:** same grader; **R1'** "Why does `assert_eq` print `got [..] want [..]` in brackets?" (Met: to make leading/trailing spaces and empty strings visible) and **R2'** "Why does the grader use a *deliberate* miss?" (Met: a harness that never fails cannot be shown to count failures; the test of a test is a known failure).
>
> **Evidence handling / reset:** as M01.

---

## Knowledge checks (predict, then run)

1. In `assert_eq "double 21" "$(double 21)" "42"`, which argument is *got* and which is *want*, and why does the order matter?
2. Why do generated fixtures make a test deterministic?
3. What does `shellcheck -x` add?
4. Where does `set -x` write its trace, and what does each line show?
5. The suite prints `# 17 passed, 0 failed` and exits 0. Which of the two should a build gate on?
6. `sha256sum -c model.sha256` prints `model.bin: OK` for a file you then overwrite with `printf 'weights-v1\n' > model.bin` — the same eleven bytes as before. What does `-c` say now, and what would it say if the file had been rewritten with the same content but by `dd … conv=notrunc`?


> **TRAINER ONLY — answers and distractors.**
> 1. Second argument *got*, third *want*; swapped, the message blames the wrong side. Tempting: "order doesn't matter for equality" — true for `==`, false for the message.
> 2. Same generator, same documented counts, identical files (observed `identical`). Tempting: "because logs are small" — size is irrelevant; determinism is.
> 3. Follows `source`d files. Tempting: "extra strictness" — it is about *scope*, not severity.
> 4. stderr; one expanded command per line with `+` (observed). Tempting: "stdout" — then `2>&1 1>/dev/null` would have hidden it.
> 5. The exit status. Tempting: "grep the summary" — brittle text matching; the status is the API (M06).

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


> **TRAINER ONLY — end of module and of the core sequence.** Debrief: "Which of today's four practices would you add to `mytool` first, and why?" (expected: the shellcheck gate — it is free and catches the quoting bugs; then a black-box test of the exit codes). **Next:** issue **A-10** (separate page): 1 hour, `labs/capstone/exercise/`, 12-check rubric, 150-word decisions note — the integrative practical before M09. **Prepare M09:** Docker Desktop/Engine running on each learner machine (S00.1); learners who deferred Docker must complete S00.1–S00.3 now. **Session close:** record A-09; collect `work/assert.sh` and `work/REFLECTION.md`.