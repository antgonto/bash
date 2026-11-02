# M04 — Functions and libraries
**FULL TRAINER EDITION · curriculum v2.0.0-draft · self-paced, no fixed duration**

> **TRAINER ONLY — about this edition.** Student text verbatim; trainer blocks inserted. IDs: S04.1–S04.5, LAB-04, A-05.
>
> **Prep (≈15 min).** `cd labs/lab4-functions/exercise && rm -rf work && bash grade.sh` → **observed** `---- lab4: 2 passed, 7 failed ----`; `GRADE_TARGET="$PWD/solution" bash grade.sh` → **observed** `---- lab4: 9 passed, 0 failed ----`; `bash labs/lab4-functions/lab.sh` → **observed** `---- lab4: 16 passed, 0 failed ----`. The walkthrough sources `logsleuth/lib/util.sh` and `lib/parse.sh` directly — confirm `logsleuth/lib/` is intact in every learner checkout (`ls logsleuth/lib` → `parse.sh report.sh util.sh`).
>
> **Trainer effort:** prep 15 min; A-05 review ≈ 5 min per learner.
>
> **Facilitator pathway (optional 40-min session).** 0–8 min: S04.2 live — the leak is the moment of the module; let the room predict before you run `careful`. 8–18 min: S04.3 self-paced; circulate on the `return 300` line. 18–35 min: LAB-04. 35–40 min: debrief R1 with the "what if the predicate printed `true`" question.


**Outcome LO-05.** You can structure a script into functions that take arguments,
keep their variables to themselves with `local`, return a **status** when they
answer yes/no and **print** when they produce a value — and you can put those
functions in a library file that any script `source`s.

**What you'll build.** `logsleuth`'s two classifier functions — the predicate
`is_valid_status` and the producer `status_class` — in
`labs/lab4-functions/exercise/` (graded as A-05).

**Prerequisite check.** A-04 passed. You use S02.2 (`[[ =~ ]]`), S02.4 (message on
stderr, verdict in the status) and S01.3 (`${var:0:1}`-style slicing).

---

## Activity context for S04.1–S04.5

| Field | Value |
|---|---|
| Execution context | Inside the course container (or fallback shell), in a scratch folder: `mkdir -p ~/bash-course-work/lab4 && cd ~/bash-course-work/lab4` |
| Starting state | `bash tools-check.sh` reports ready |
| Validation status | Every expected output in S04.1–S04.5 was **observed** in the authoring environment (bash 5.2.21, GNU make 4.3; 2026-10-19, S04.5 and the reading on 2026-10-26). In S04.5 the directory prefix is your `$HOME` (`/home/learner` in the container) |

### S04.1 — Define, then call: a function is a tiny script
- **Purpose.** See that a function receives arguments exactly the way a script does. (SK-05)
- **Exact action.**
  ```bash
  greet() { printf 'hello, %s (%d args)\n' "$1" "$#"; }
  greet Ana
  greet Ana Luis
  ```
- **Expected observation (observed).**
  ```text
  hello, Ana (1 args)
  hello, Ana (2 args)
  ```
- **Verification.** Two lines; the second shows `2 args` although only `Ana` was printed.
- **Recovery.** `greet: command not found` → you called it *before* the definition (bash reads top to bottom; in a script this exits 127, observed). `syntax error near unexpected token` → a missing space after `{` or a missing `;` before `}`.
- **Evidence / next state.** **Why:** inside a function `$1…$9`, `$#`, and `"$@"` refer to the *function's* arguments; `$0` still names the script. Define every function above the code that calls it.


> **TRAINER ONLY.** *Ask:* "What is `$0` inside a function?" *Expected:* "still the script name" (observed: `$0=zero.sh`). *Misconception:* that `function greet() {` is required or different — both forms work; the course uses `greet() {` because it is POSIX-shaped and shellcheck-friendly. *Observed, worth showing:* a script that calls `hello` on line 3 and defines it on line 4 prints `hello: command not found` and exits **127** under the house header — the same code as a misspelled command, which is a good hint for learners debugging "but I defined it!".

### S04.2 — `local`, or it leaks
- **Purpose.** Watch a function overwrite the caller's variable, then stop it.
- **Exact action.**
  ```bash
  leaky()   { x=leaked; }
  careful() { local x=safe; }
  x=outer; leaky;   echo "after leaky:   $x"
  x=outer; careful; echo "after careful: $x"
  ```
- **Expected observation (observed).**
  ```text
  after leaky:   leaked
  after careful: outer
  ```
- **Verification.** The two lines differ exactly as shown.
- **Recovery.** Both say `outer` → you wrote `local` in both functions. Both say `leaked` → `local` is missing or misspelled in `careful`.
- **Evidence / next state.** **Why:** every variable in bash is global unless declared `local` inside a function. `logsleuth` declares *every* function variable `local` — a function that quietly changes `line` or `count` for its caller is a bug you will spend an hour finding.


> **TRAINER ONLY — scope is dynamic, not lexical (observed).** `outer() { local secret=shh; inner; }; inner() { echo "inner sees: ${secret:-nothing}"; }; outer` → `inner sees: shh`. A `local` is visible to every function *called from* the one that declared it — bash scopes by call chain, not by file position. Teach the consequence as a habit, not a theory: "declare every variable `local` in every function; then nothing can see anything by accident." *Second observed gotcha, for a learner who asks why the reference writes `local v` and `v="$(…)"` on separate lines:* `local v="$(false)"; echo $?` → `0` — `local`'s own status masks the substitution's; `local v; v="$(false)"; echo $?` → `1`. This matters under `set -e` and is knowledge check 3.

### S04.3 — Two ways to answer: a status or an output
- **Purpose.** Learn the single most useful design rule for shell functions: **predicates return a status; producers print a value.**
- **Exact action.**
  ```bash
  is_valid_status() { [[ "$1" =~ ^[1-5][0-9][0-9]$ ]]; }      # predicate: its status IS the test
  status_class() {                                             # producer: prints, captured with $( )
    if is_valid_status "$1"; then printf '%sxx\n' "${1:0:1}"; else printf 'unknown\n'; fi
  }
  is_valid_status 404 && echo "404 valid"
  is_valid_status 999 || echo "999 invalid (status $?)"
  class="$(status_class 503)"; echo "class=$class"
  big() { return 300; }; big; echo "return 300 gives status $?"
  ```
- **Expected observation (observed).**
  ```text
  404 valid
  999 invalid (status 1)
  class=5xx
  return 300 gives status 44
  ```
- **Verification.** Four lines; the last one is **44**, not 300.
- **Recovery.** `999 invalid` missing → the regex is quoted (`"^[1-5]…"` is then a literal); keep `=~` patterns unquoted. `class=` empty → `status_class` used `return` instead of `printf`.
- **Evidence / next state.** **Why 44:** a return status is one byte (0–255); 300 wraps to 44. That is the proof that `return` cannot carry data — it carries a verdict. Data goes to **stdout** and is captured with `$( )`; messages for humans go to **stderr** (S02.4). The last line of a predicate is the test itself — no `if … then return 0; else return 1; fi` needed.


> **TRAINER ONLY — predicates and `set -e` (observed).** With `set -e`, `p() { return 1; }; if p; then …; else echo no; fi` prints `no` and continues — a status that is *tested* never aborts. But a bare `p` as a statement aborts the script (exit 1, nothing after it runs). Rule to say out loud: "a predicate is only safe to call where its status is consumed — `if`, `&&`, `||`, `while`." *The `return 42` anti-pattern, observed:* `answer() { return 42; }; v="$(answer)"; echo "captured=[$v] status=$?"` → `captured=[] status=42` — the value went to the status, nothing was captured, and the assignment itself reports 42 (an assignment's status is its command substitution's). *Misconception:* "`return` is like other languages' return of a value" — the 300 → 44 observation is the cure; make every learner run it.

### S04.4 — A library is a file you `source`
- **Purpose.** Put functions in one file and reuse them from any script — the shape of `logsleuth` and of M09's `stackctl`.
- **Exact action.** (The `<<'EOF' … EOF` block writes the lines between the markers into the file — a *here-document*; M05 covers it properly.)
  ```bash
  cat > mathlib.sh <<'EOF'
  # shellcheck shell=bash
  add() { printf '%s\n' "$(( $1 + $2 ))"; }
  EOF
  bash ./mathlib.sh; type add 2>&1 | head -1      # running it defines nothing here
  source ./mathlib.sh; type add 2>&1 | head -1    # sourcing it does
  add 40 2
  ```
- **Expected observation (observed).**
  ```text
  bash: type: add: not found
  add is a function
  42
  ```
- **Verification.** Three lines in that order (the first ends with `type: add: not found`; its prefix varies by shell).
- **Recovery.** `add is a function` on the first line → you had sourced it earlier in this shell; `unset -f add` and repeat. `42` missing → the `add() …` line was mistyped inside the here-document; `cat mathlib.sh` and compare.
- **Evidence / next state.** **Why:** `bash file` runs it in a *new* process whose definitions vanish when it exits; `source file` (or `. file`) reads it into the *current* shell. `logsleuth` is exactly this: a thin `bin/logsleuth` that `source`s `lib/util.sh`, `lib/parse.sh` and `lib/report.sh`, then dispatches with `case` (S02.3). A library has no shebang and runs nothing at top level — it only defines.


> **TRAINER ONLY.** *Ask:* "Why does a library file have no shebang and no top-level commands?" *Expected:* "it is never *run*, only *read* into another shell; top-level commands would execute at `source` time inside the caller." *Point at the real thing:* `logsleuth/bin/logsleuth` sets `LIB="$HERE/../lib"` and sources `util.sh`, `parse.sh`, `report.sh` in that order (util first because the others call `die`/`warn`/`trim`). The `# shellcheck shell=bash` directive exists precisely because a shebang-less file gives shellcheck no dialect. *Security note to foreshadow M09:* `source` executes everything in the file — which is why `load_config` in `lib/util.sh` *parses* `top_n = 7` with `IFS='=' read -r` and a `case` whitelist and never sources the config (observed in the walkthrough's last check).

### S04.5 — Find the library from the script, not from wherever you are
- **Purpose.** `source ./lib/x.sh` works only when you *run* the script from its own directory; a CI runner, `make`, or a cron job runs it from somewhere else. Every `ci/*.sh` in Course 2 opens with `source "$(dirname "$0")/versions.env"` for this reason.
- **Exact action.**
  ```bash
  mkdir -p tool/lib elsewhere
  printf 'hello(){ echo "hello from the library"; }\n' > tool/lib/greet.sh
  printf '#!/usr/bin/env bash\nset -euo pipefail\nsource ./lib/greet.sh\nhello\n' > tool/naive
  printf '#!/usr/bin/env bash\nset -euo pipefail\nHERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"\necho "script lives in: $HERE"\nsource "$HERE/lib/greet.sh"\nhello\n' > tool/robust
  chmod +x tool/naive tool/robust
  (cd tool && ./naive); echo "status=$?"
  (cd elsewhere && ../tool/naive); echo "status=$?"
  (cd elsewhere && ../tool/robust); echo "status=$?"
  ```
- **Expected observation (observed; the prefix before `/bash-course-work` is your home directory).**
  ```text
  hello from the library
  status=0
  ../tool/naive: line 3: ./lib/greet.sh: No such file or directory
  status=1
  script lives in: /home/learner/bash-course-work/lab4/tool
  hello from the library
  status=0
  ```
- **Verification.** `naive` works from its own directory and fails from `elsewhere/` with `No such file or directory`; `robust` works from `elsewhere/` and prints an absolute path ending in `/lab4/tool`.
- **Recovery.** `robust` also fails → the `HERE=` line was mistyped; it must be exactly `"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` — nested `$( )` with their own double quotes inside. `status=0` for the second call → you ran it from `tool/` (check the `cd`). `script lives in: …/elsewhere/../tool` → you wrote `dirname` without the `cd … && pwd`; that form still works but is not canonical.
- **Evidence / next state.** **Why:** `./lib/greet.sh` is relative to the *current directory* of whoever runs the script; `$0` (or `${BASH_SOURCE[0]}`, which is also right when the file is *sourced*) is the path the script was invoked by, and `dirname` strips the file name — `cd … && pwd` then turns a relative path like `../tool` into an absolute one. `logsleuth` and `stackctl` both open this way (`bin/logsleuth` line 16; `bin/stackctl` line 12). **The program's own line:** `source "$(dirname "$0")/versions.env"` in `ci/gates.sh`, `ci/deploy.sh`, `ci/promote.sh` — the pinned tool versions are read from a file *next to the script*, wherever the runner's working directory happens to be. Course 2 Labs 3.1 and 4.1 have you type that line yourself.


> **TRAINER ONLY (added Batch 7, 2026-10-26; observed, bash 5.2).** *Why this step exists:* `source "$(dirname "$0")/versions.env"` opens every `ci/*.sh` the learner will write in Course 2 Labs 3.1 and 4.1, and `bin/logsleuth` line 16 / `bin/stackctl` line 12 use the `cd … && pwd` form — the course showed the idiom in its own tools and never taught it. *Ask:* "Why does `../tool/naive` fail from `elsewhere/` when it worked a second ago?" *Expected:* "`./lib/greet.sh` is resolved against the *caller's* directory." *Tempting:* "the file moved" — nothing moved. *The nested quoting* `"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` is where typing errors land; show that the inner double quotes are legal because each `$( )` starts a new quoting context (S01.2). *If asked `$0` vs `BASH_SOURCE`:* when a file is `source`d, `$0` is still the *outer* script, `BASH_SOURCE[0]` is the sourced file — that is why libraries use the latter. *The Makefile reading* (after the bridge) is observed with GNU make 4.3: the `shell var: []` line is the one that surprises everyone; let them predict it first. Line references into `program/Makefile` (32, 61–62, 83) are to the Course 1 file as shipped on 2026-10-26.

---

## Worked demonstration (10 min)

```bash
cd /course
bash labs/lab4-functions/lab.sh
```
**Expected observation (observed).** `---- lab4: 16 passed, 0 failed ----`. It replays
S04.1–S04.4 with assertions (arguments and `$#`, the leak with and without `local`,
predicate vs producer, explicit return codes `0/1/2` for `2xx/4xx/5xx`, a sourced
`mathlib.sh`), then sources `logsleuth`'s own `lib/util.sh` and `lib/parse.sh` and
calls them directly: `field_status` yields 85 lines of `200`, `failed_login_ips`
finds `203.0.113.9`, `count_col` ranks `10.0.0.1` first, and `load_config` sets
`TOP_N=7` from a file **as data**. Read `lab.sh` beside the output; the project
section shows what "a library" means at real size.


> **TRAINER ONLY — what `lab.sh` asserts (16 checks, observed).** `$1` and `$#`; the leak (`leaked`) vs `local` (`outer`); predicate success for 404 / failure for `xx`; captured output `4xx`; data from stdout not `return` (`42`); explicit `classify` codes `0/1/2` for `2xx/4xx/5xx`; a sourced `mathlib.sh` (`add 40 2` → 42); then the project: `field_status` has 85 lines of `200`, `failed_login_ips` contains `203.0.113.9`, `count_col … 1 1` ranks `10.0.0.1` first, and `load_config ./c.conf` sets `TOP_N=7` from `top_n = 7`. The final `cleanup` call proves the library's temp-dir cleanup is a no-fail.

---

## LAB-04 — Your exercise (graded as A-05) — 45 min

| Field | Value |
|---|---|
| Location | `labs/lab4-functions/exercise/` (read `TASK.md`) |
| Starting assets | `starter/classify.sh` (`is_valid_status` always returns 0; `status_class` prints `FIXME`), `grade.sh` |
| Allowed resources | This module, documentation, AI assistance (disclosed); **not** `solution/` |
| Deliverables | `work/classify.sh` passing the grader; `work/REFLECTION.md` with R1 and R2 |
| Acceptance | `bash grade.sh` ends `---- lab4: 9 passed, 0 failed ----`; both reflections present |

**Procedure.**
1. `cd labs/lab4-functions/exercise && bash grade.sh`. **Observed on the starter:** `---- lab4: 2 passed, 7 failed ----` (the unconditional `return 0` accepts `200` and `404` — and everything else).
2. Edit `work/classify.sh`:
   - `is_valid_status`: make the regex test the function's last (and only) command: `[[ "$code" =~ ^[1-5][0-9][0-9]$ ]]` (S04.3). Print nothing.
   - `status_class`: `if is_valid_status "$code"; then printf '%sxx\n' "${code:0:1}"; else printf 'unknown\n'; fi` (S04.3).
3. Re-run until **`---- lab4: 9 passed, 0 failed ----`** (observed with the reference). The nine checks: `200` and `404` are valid; `999`, `4xx` and `20` are **not**; `404 → 4xx`; `503 → 5xx`; `200 → 2xx`; `nope → unknown`.
4. `work/REFLECTION.md`:
   - **R1.** `is_valid_status` prints nothing and `status_class` returns nothing meaningful. Explain the rule behind that split, and say what would break for a caller like `if is_valid_status "$c"` if the predicate *printed* `true`/`false` instead.
   - **R2.** In S04.3, `return 300` produced status 44. What does that tell you about using `return` to hand back a count, and which channel should a function use for data? Quote what you observed.

**Learner-visible rubric (A-05).** *Pass* = `0 failed` **and** both reflections name the mechanism. Unlimited attempts.

**Hints.** H1: a `[[ ]]` test on its own line *is* a return value — do not wrap it in `if … return 0 … return 1`. H2: `"${code:0:1}"` is the first character. H3: if `nope → unknown` fails, your producer printed something before the test; the `if` must guard the `printf`.

**Reset.** `rm -rf work && bash grade.sh`.


> **TRAINER ONLY — complete solution (reference `solution/classify.sh`, observed 9/9):**
> ```bash
> #!/usr/bin/env bash
> # Lab 4 solution — a predicate (status) and a producer (stdout).
>
> # is_valid_status: PREDICATE — 0 if "$1" is a 1xx-5xx three-digit code.
> is_valid_status() {
>   local code="$1"
>   [[ "$code" =~ ^[1-5][0-9][0-9]$ ]]
> }
>
> # status_class: PRODUCER — print "<n>xx", or "unknown" for an invalid code.
> status_class() {
>   local code="$1"
>   if is_valid_status "$code"; then
>     printf '%sxx\n' "${code:0:1}"
>   else
>     printf 'unknown\n'
>   fi
> }
> ```
> *Acceptable variations:* `if [[ … ]]; then return 0; else return 1; fi` passes — coach to the one-line form (H1), it is the idiom they will read everywhere; `case "$code" in [1-5][0-9][0-9]) return 0;; *) return 1;; esac` passes and is fine; a `status_class` that *echoes* `${code:0:1}xx` without the guard fails `nope → unknown` (`nxx`); a predicate that `echo`es `true`/`false` passes the `check`/`denies` tests only if it *also* returns the right status — it usually does not, and R1 targets exactly this.
>
> **Grading procedure (≈5 min/learner).** 1) `GRADE_TARGET=/path/to/their/work bash labs/lab4-functions/exercise/grade.sh` → require `---- lab4: 9 passed, 0 failed ----`. 2) Reflections:
> - **R1 — Met:** predicates answer yes/no through the exit status so `if`/`&&`/`||` can consume them; producers put data on stdout so `$( )` can capture it; a predicate that printed `true`/`false` would make `if is_valid_status …` branch on the *status* (still 0 → always "then") while the words leak into stdout. **Strong:** notes that mixing both forces every caller to parse text, or mentions stderr as the third channel for messages. **Not met:** "one returns and one prints" with no consequence for the caller.
> - **R2 — Met:** a return status is a single byte (0–255), so 300 became 44; `return` carries a verdict, not data; data goes to stdout and is captured with `$( )`; quotes the observed `44`. **Strong:** adds that `$(…)` of a function that only `return`s captures nothing (`captured=[]`), or that `return` is for callers testing status. **Not met:** "bash can't return big numbers" without the channel conclusion, or no observation.
>
> 3) Record `A-05 PASS` only with 9/9 and both reflections ≥ Met.
>
> **Calibration.** *R1 Met:* "`is_valid_status` is used inside `if`, which reads the exit status, so its whole job is to exit 0 or 1 and stay silent; `status_class` is used inside `$( )`, which reads stdout. If the predicate printed `true`, `if` would ignore the word and the word would end up in whatever captured the output." *R1 Not met:* "A predicate returns and a producer prints because that is the convention."
>
> **Model feedback (Not yet):** "`'4xx' is not valid` failed: your predicate still ends with `return 0` — delete the stub line so the `[[ ]]` test is the last command." **Remediation:** S04.3. **Equivalent reassessment:** same grader; **R1'** "Why does the reference declare `local code="$1"` instead of using `$1` directly?" (Met: readability/naming, and `local` keeps it from leaking if the function later assigns) and **R2'** "Give one situation where a producer should write to stderr." (Met: a diagnostic/progress message that must not end up in captured data).
>
> **Evidence handling / reset:** as M01.

---

## Knowledge checks (predict, then run)

1. In a script, what does `$0` print *inside* a function?
2. A script calls `hello` on line 3 and defines `hello()` on line 4. What happens?
3. Inside a function, `local v="$(false)"; echo "$?"` prints what — and why?
4. What is in `$?` after a function runs `return 300`?
5. After `bash ./lib.sh`, can the current shell call a function defined in `lib.sh`? After `source ./lib.sh`?
6. A script does `source ./lib/x.sh`. From which directory does it work, and what does `"$(dirname "$0")/lib/x.sh"` change?


> **TRAINER ONLY — answers and distractors.**
> 1. The script name (observed `$0=zero.sh`). Tempting: the function name — bash has `FUNCNAME` for that; out of scope.
> 2. `hello: command not found`, exit 127 (observed). Tempting: "bash hoists definitions" — it does not; it reads top to bottom.
> 3. `0` — `local`'s status masks the substitution's (observed; `local v; v="$(false)"` gives `1`). Tempting: `1`.
> 4. `44` (300 mod 256, observed). Tempting: `300` or an error.
> 5. No after `bash` (`type add` → not found); yes after `source` (observed). Tempting: "both, once the file ran" — a child process's definitions die with it.
> 6. Only from the script's own directory; `$(dirname "$0")` resolves the library next to the script instead of under the caller's cwd (observed `No such file or directory` from `elsewhere/`). Tempting: "use an absolute path" — breaks the moment the tree is moved or cloned elsewhere.

---

## In the SecMLOps Program
Course 2's `scripts/ready-check.sh` is three one-line functions — `ok`, `warnf`, `failf` — each a `printf` with a format string, and two counters they increment; it is today's status-vs-output lesson in production. Course 2's pattern "`ci/*.sh` + thin per-platform wrappers" is S04.4's sourced library: the logic lives in bash files every platform calls, the GitHub workflow, GitLab job and Azure stage are only the callers. One thing you can now see in `ci/release.sh`: `export COSIGN_PASSWORD="$(bao kv get …)"` assigns and exports in one statement, so the command's exit status is lost — M08's shellcheck gate flags exactly this (SC2155).

**Read the real thing (the Course 1 `Makefile`).** Open `program/Makefile` — it is the `make up` / `make smoke` / `make ready` menu you will drive in Course 1 and `make ssh` in Course 2. A Makefile target is a function with no arguments: a name, then indented *recipe* lines. Three rules make it readable, and a two-minute experiment proves them:
```bash
cd /course && mkdir -p ~/bash-course-work/lab4/mk && cd ~/bash-course-work/lab4/mk
printf 'NAME ?= world\n\nhello:\n\t@echo "hello $(NAME)"\n\twhere=$$(pwd)\n\t@echo "shell var: [$$where]"\n\ncd-test:\n\tcd /tmp\n\tpwd\n\tcd /tmp && pwd\n\nready: hello\n\t@test -n "$(TOKEN)" || (echo "set TOKEN=..." && exit 1)\n\t@echo ready\n' > Makefile
make hello; make NAME=course hello; make cd-test; make ready; echo "status=$?"; make ready TOKEN=x
```
Observed (GNU make 4.3): `hello world` — then `where=$(pwd)` echoed and `shell var: []`; `hello course`; the `cd-test` lines echo and `pwd` prints *this* directory while `cd /tmp && pwd` prints `/tmp`; `make ready` prints `hello world …`, `set TOKEN=...`, `make: *** [Makefile:14: ready] Error 1` and `status=2`; with `TOKEN=x` it ends `ready`. The three rules: (1) **each recipe line runs in its own shell** — a `cd` or a variable on one line is gone on the next, which is why the real Makefile writes `cd tofu/local && tofu init … && tofu apply` on *one* line; (2) **`$` belongs to make** — `$(NAME)` is a make variable set from the command line (`make NAME=course`), and a shell `$` must be written `$$` (`$$(pwd)`, `$${WIN_IP:-…}` in `program/Makefile` line 83); (3) a leading `@` hides the echo of the line, and a failing line fails the target (`Error 1`) exactly like `set -e` — `program/Makefile` lines 61–62 guard `make agent` with the same `test -n … || (echo … && exit 1)` you just ran. In `work/REFLECTION.md` for LAB-04, add one sentence on which S04 habit the `cd … && …` rule corresponds to.

---

## Recap and transfer
Arguments like a script; `local` always; status for yes/no, stdout for data,
stderr for people; `source` a library. **Transfer:** M05 wraps text pipelines in
exactly these producers; M08 tests functions by sourcing the library — the
predicate/producer split is what makes a function testable in one line; M09's
`stackctl` is a library of predicates (`validate`) and actions (`apply`,
`destroy`) whose statuses drive the whole run.

---

## Self-check answers

1. The script's name (observed: `$0=zero.sh`), not the function's — `$1…` change inside a function, `$0` does not.
2. `hello: command not found` and, with the house header, the script exits 127 (observed) — definitions must come before calls.
3. `0` — `local` is itself a command and its (successful) status masks the substitution's. Declare first, then assign on its own line (`local v; v="$(false)"` → `1`, observed).
4. `44` — a status is one byte, 300 mod 256 = 44 (observed).
5. No after `bash` (new process; `type add` → `not found`); yes after `source` (`add is a function`), both observed.
6. Only from the script's own directory (observed: `No such file or directory` from `elsewhere/`); `dirname "$0"` makes the path relative to the script's location instead of the caller's, so it works from anywhere (S04.5).


> **TRAINER ONLY — end of module.** Debrief: "Name the three channels a function has and what each is for." (expected: status → verdict; stdout → data; stderr → messages). **Prepare M05:** confirm `awk --version` reports GNU Awk (gawk) in the container — M05's pipelines assume it; `sort`, `uniq`, `sed` from coreutils are present. **Session close:** record A-05; collect `work/classify.sh` and `work/REFLECTION.md`. **Progress note for the cohort sheet:** learners who passed A-02…A-05 hold SK-02–SK-05 — the whole core-language half of the skills model — and may be told so.