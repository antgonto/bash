# M04 — Functions and libraries
**Student Edition · curriculum v2.0.0-draft · self-paced, no fixed duration**

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

---

## Knowledge checks (predict, then run)

1. In a script, what does `$0` print *inside* a function?
2. A script calls `hello` on line 3 and defines `hello()` on line 4. What happens?
3. Inside a function, `local v="$(false)"; echo "$?"` prints what — and why?
4. What is in `$?` after a function runs `return 300`?
5. After `bash ./lib.sh`, can the current shell call a function defined in `lib.sh`? After `source ./lib.sh`?
6. A script does `source ./lib/x.sh`. From which directory does it work, and what does `"$(dirname "$0")/lib/x.sh"` change?

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
