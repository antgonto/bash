# M02 — Conditionals and `case`
**Student Edition · curriculum v2.0.0-draft · self-paced, no fixed duration**

**Outcome LO-03.** You can branch on a command's status, test files/strings/numbers
with the safe `[[ ]]`, express guards with `&&`/`||`, and dispatch subcommands with
`case` — refusing bad input with a clear message and a non-zero exit.

**What you'll build.** `logsleuth`'s two gatekeepers — `validate_log` and `route` —
in `labs/lab2-conditionals/exercise/` (graded as A-03).

**Prerequisite check.** A-02 passed. You use S00.8 (exit codes) and S01.2 (quoting).

---

## Activity context for S02.1–S02.4

| Field | Value |
|---|---|
| Execution context | Inside the course container (or fallback shell), at the prompt; a scratch folder is optional |
| Starting state | `bash tools-check.sh` reports ready |
| Validation status | Every expected output in S02.1–S02.4 was **observed** in the authoring environment (bash 5.2.21, 2026-10-19) |

### S02.1 — `if` tests a command, not a boolean
- **Purpose.** Internalize the whole model: `if` runs a command and branches on its exit status. (SK-03)
- **Exact action.**
  ```bash
  if grep -q root /etc/passwd; then echo found; else echo missing; fi
  ```
- **Expected observation (observed).** `found`
- **Verification.** One word. (`grep -q` prints nothing; only its status matters.)
- **Recovery.** `missing` → no `root` entry in that file on your system (unusual but possible); try `grep -q bin /etc/passwd`. A syntax error → check the `; then` and `; fi` separators.
- **Evidence / next state.** **Why:** `grep -q`, `test`, `[[ … ]]` are just commands that return 0 (true) or non-zero (false). Everything in this module is built from that.

### S02.2 — Prefer `[[ ]]`: file, string, glob, and regex tests
- **Purpose.** Use the test construct that does not word-split or glob its operands.
- **Exact action.**
  ```bash
  f=/etc/hostname
  [[ -r "$f" ]] && echo readable          # -e exists  -f regular file  -d dir  -r readable  -s non-empty
  [[ "$f" == *hostname ]] && echo "matches a glob"
  [[ "404" =~ ^[0-9]{3}$ ]] && echo "matches a regex"
  ```
- **Expected observation (observed).**
  ```text
  readable
  matches a glob
  matches a regex
  ```
- **Verification.** Three lines.
- **Recovery.** No `readable` → the file does not exist or is unreadable on your system; use `/etc/passwd`. `matches a glob` missing → you quoted the pattern (`"*hostname"` is then a literal). `matches a regex` missing → you quoted the regex; keep `=~` patterns unquoted.
- **Evidence / next state.** **Why `[[ ]]`:** with the old `[ ]`, an empty variable breaks the syntax (`[: =: unary operator expected`, observed); `[[ ]]` handles it, and adds `==` globbing and `=~` regex. **Read both.** The program's own scripts use POSIX `[ ]` throughout (38 tests in Course 1/2, no `[[ ]]`) because some of them must also run under `sh`, where `[[` does not exist (observed: `sh -c '[[ -f /etc/hosts ]]'` → `[[: not found`). The rule when you *read* them: `[ -f "$s" ]` is the same file test as `[[ -f $s ]]`, but inside `[ ]` the quotes are not optional — `[ -f $f ]` with `f="my file.txt"` fails with `binary operator expected` (observed). When you *write* bash in this course, keep `[[ ]]`.

### S02.3 — `case` dispatches on a value
- **Purpose.** Route a subcommand name to an action — the shape of every CLI's front door.
- **Exact action.**
  ```bash
  route() {
    case "$1" in
      summary|top|errors) echo valid ;;
      brute*)             echo brute ;;
      *)                  echo unknown ;;
    esac
  }
  route summary; route bruteforce; route frobnicate
  ```
- **Expected observation (observed).**
  ```text
  valid
  brute
  unknown
  ```
- **Verification.** Three lines in that order.
- **Recovery.** `unknown` for `summary` → a typo in the pattern list or a missing `|`. Nothing printed → a missing `;;` swallowed the next pattern; every branch ends with `;;`.
- **Evidence / next state.** **Why:** `case` matches *glob* patterns top to bottom, first match wins, `*` is the catch-all. `logsleuth` turns `summary`/`top`/`bruteforce`/… into function calls exactly this way, and sends an unknown command to usage with exit 2.

### S02.4 — Guard, then act
- **Purpose.** Refuse bad input cleanly: a message a human can read **and** a status a program can test.
- **Exact action.**
  ```bash
  validate_log() {
    local f="$1"
    if [[ -r "$f" ]]; then return 0
    else printf 'cannot read log file: %s\n' "$f" >&2; return 1
    fi
  }
  validate_log /etc/hostname && echo "ok"
  validate_log /nope.log || echo "refused (exit $?)"
  ```
- **Expected observation (observed).**
  ```text
  ok
  cannot read log file: /nope.log
  refused (exit 1)
  ```
- **Verification.** Three lines; the message appears *before* `refused`.
- **Recovery.** `refused (exit 0)` → you forgot `return 1`. Message missing → you wrote `>&2` before the string or omitted it; the message goes to **stderr** on purpose so it never pollutes data on stdout.
- **Evidence / next state.** You have `validate_log`. **Why two channels:** stderr carries the explanation for people; the exit status carries the verdict for programs (`&&`/`||`, M00 S00.8).

---

## Worked demonstration (10 min)

```bash
cd /course
bash labs/lab2-conditionals/lab.sh
```
**Expected observation (observed).** `---- lab2: 23 passed, 0 failed ----`. It shows
`if` branching on status, the `[[ ]]` family (string, glob, regex, numeric, and
file tests on the fixtures), `&&`/`||` guards, a `case` router — then the real
tool: a missing file exits 1 with `cannot read log file`, an unknown subcommand
exits 2, a valid one reports.

---

## LAB-02 — Your exercise (graded as A-03) — 35 min

| Field | Value |
|---|---|
| Location | `labs/lab2-conditionals/exercise/` (read `TASK.md`) |
| Starting assets | `starter/router.sh` (`validate_log` always returns 0; `route` prints `FIXME`), `grade.sh` |
| Allowed resources | This module, documentation, AI assistance (disclosed); **not** `solution/` |
| Deliverables | `work/router.sh` passing the grader; `work/REFLECTION.md` with R1 and R2 |
| Acceptance | `bash grade.sh` ends `---- lab2: 7 passed, 0 failed ----`; both reflections present |

**Procedure.**
1. `cd labs/lab2-conditionals/exercise && bash grade.sh`. **Observed on the starter:** `---- lab2: 1 passed, 6 failed ----` (the stub's unconditional `return 0` passes the "readable file" check and fails the rest).
2. Edit `work/router.sh`: `validate_log` as in S02.4 (readable → `return 0`; else message to stderr and `return 1`); `route` as in S02.3.
3. Re-run until **`---- lab2: 7 passed, 0 failed ----`** (observed with the reference). The checks: readable file validates; missing file fails (non-zero); missing file prints `cannot read log file`; `summary` → `valid`; `errors` → `valid`; `bruteforce` → `brute`; `frobnicate` → `unknown`.
4. `work/REFLECTION.md`:
   - **R1.** `if` works with `grep`, with `[[ ]]`, and with your own functions. What is the *one* thing `if` actually tests?
   - **R2.** `validate_log` both prints a message and returns 1. Who consumes each, and what would break if you printed the message to stdout instead?

**Learner-visible rubric (A-03).** *Pass* = `0 failed` **and** both reflections name the mechanism. Unlimited attempts.

**Hints.** H1: read the first FAIL's `expected [...] got [...]`. H2: the message must contain the exact phrase `cannot read log file`. H3: in `case`, `brute*` is a pattern — no quotes.

**Reset.** `rm -rf work && bash grade.sh`.

---

## Knowledge checks (predict, then run)

1. With `v=""`, why does `[ $v = x ]` error but `[[ $v = x ]]` does not?
2. In `case`, after the first matching branch runs, does bash try the later ones?
3. Is `[[ "abc" == a* ]]` true?
4. What exit status does `[[ -r /nope ]]` give?
5. Does the pattern `brute*` match both `bruteforce` and `brute`?

---

## In the SecMLOps Program
Course 2's gates are `if`s with exit codes. `ci/gates.sh` runs `[ -d /tmp/opengrep-rules ] || git clone …` (a file test deciding whether to fetch); `ci/sarif_gate.sh` ends with `[ "$total" -eq 0 ] && echo "SARIF-GATE-PASS" || { echo "CRITICAL findings: $total → exit 1"; exit 1; }` — the `&& … ||` chain from S02.4, safe here because the middle command is a plain `echo` that will not fail; `ci/validate_unauth.sh` lets `jq -e` decide (`&& { echo "CRITICAL in $s"; exit 1; }`). `logsleuth`'s `case` dispatcher is the shape of every `ci/*.sh` stage selector and of Course 1's `lab.ps1`/`Makefile` target menu.

---

## Recap and transfer
Branch on status; test with `[[ ]]`; guard with `&&`/`||`; dispatch with `case`;
refuse bad input on two channels. **Transfer:** M03 loops over the data these
guards admit; M09's `stackctl validate` is this module scaled up — every check
before any mutation.

---

## Self-check answers

1. `[ ]` is an ordinary command whose arguments are word-split: with `v` empty it sees `[ = x ]` → `unary operator expected` (observed, exit 2). `[[ ]]` is a keyword that parses its operands itself, so an empty value is just an empty string.
2. No — first match wins and `;;` ends the statement.
3. True — `==` inside `[[ ]]` does glob matching when the right side is unquoted.
4. `1` (false).
5. Yes — `*` also matches the empty string, so `brute` matches too.
