# M06 — A real command line: arguments, `getopts`, stdin-or-file, exit codes
**Student Edition · curriculum v2.0.0-draft · self-paced, no fixed duration**

**Outcome LO-07.** You can give a script the command line other people expect:
positional arguments, short options parsed with `getopts` (with proper error
handling), input from a named file *or* from stdin so it composes in pipelines,
and distinct exit codes that act as the tool's API.

**What you'll build.** `logsleuth`'s option parser and input reader — `parse_opts`
and `read_input` — in `labs/lab6-arguments/exercise/` (graded as A-07).

**Prerequisite check.** A-05 passed. You use S04.1 (`$1`, `$#`, `"$@"` inside
functions), S02.3 (`case`) and S02.4 (message on stderr, verdict in the status).

---

## Activity context for S06.1–S06.6

| Field | Value |
|---|---|
| Execution context | Inside the course container (or fallback shell), in a scratch folder: `mkdir -p ~/bash-course-work/lab6 && cd ~/bash-course-work/lab6` |
| Starting state | `bash tools-check.sh` reports ready; `bash logsleuth/bin/logsleuth -h` prints usage (S06.5 uses the real tool) |
| Validation status | Every expected output in S06.1–S06.5 was **observed** in the authoring environment (bash 5.2.21, 2026-10-19) |

### S06.1 — Positional parameters and `shift`
- **Purpose.** Know exactly what `$1`, `$#`, `"$@"` and `"$*"` hold, and how `shift` walks the list. (SK-07)
- **Exact action.**
  ```bash
  show() { printf 'first=%s count=%d all=[%s]\n' "$1" "$#" "$*"; shift; printf 'after shift: first=%s count=%d\n' "${1:-}" "$#"; }
  show a "b c" d
  set -- 'x y' z          # set the shell's own $1 $2 for the next two lines
  printf '[%s]' "$@"; echo
  printf '[%s]' "$*"; echo
  ```
- **Expected observation (observed).**
  ```text
  first=a count=3 all=[a b c d]
  after shift: first=b c count=2
  [x y][z]
  [x y z]
  ```
- **Verification.** Four lines; note `"$@"` kept `x y` as *one* argument while `"$*"` joined everything into one string.
- **Recovery.** `count=4` on the first line → you forgot the quotes around `"b c"` on the call. `[x][y][z]` → you wrote `$@` unquoted (it word-splits like any unquoted expansion, S01.2).
- **Evidence / next state.** **Why:** `"$@"` is the only form that passes arguments through *unchanged* — use it to forward arguments (`main "$@"`); `"$*"` is for building one message. `shift` discards `$1` and renumbers the rest.

### S06.2 — `getopts` parses short options
- **Purpose.** Accept `-n 5`, `-v`, bundled `-vn 3` — and reject mistakes with a clear message and status 2.
- **Exact action.**
  ```bash
  parse() {
    local n=10 v=0 OPTIND opt
    while getopts ":n:v" opt; do
      case "$opt" in
        n)  n="$OPTARG" ;;
        v)  v=1 ;;
        :)  printf 'error: -%s needs an argument\n' "$OPTARG" >&2; return 2 ;;
        \?) printf 'error: unknown option -%s\n' "$OPTARG" >&2; return 2 ;;
      esac
    done
    shift $((OPTIND-1))
    printf 'n=%s v=%s rest=%s\n' "$n" "$v" "$*"
  }
  parse -n 5 -v access.log
  parse access.log
  parse -v cmd -n 9
  parse -vn 3 f
  parse -n; echo "status=$?"
  parse -z; echo "status=$?"
  ```
- **Expected observation (observed).**
  ```text
  n=5 v=1 rest=access.log
  n=10 v=0 rest=access.log
  n=10 v=1 rest=cmd -n 9
  n=3 v=1 rest=f
  error: -n needs an argument
  status=2
  error: unknown option -z
  status=2
  ```
- **Verification.** Eight lines as shown; the two error lines end with `status=2`.
- **Recovery.** `bash: illegal option -- z` or `bash: option requires an argument -- n` printed *by bash*, with your own message missing → you dropped the leading `:` from `":n:v"`; getopts then reports errors itself, both cases arrive as `?` with an **empty** `OPTARG`, and your `:` branch never runs (observed). `rest=-n 5 -v access.log` → the `shift $((OPTIND-1))` line is missing.
- **Evidence / next state.** **Why each piece:** the optstring `":n:v"` says `-n` takes an argument (the `:` after `n`), `-v` does not; the *leading* `:` puts getopts in silent mode so that a missing argument arrives as `opt=:` and an unknown option as `opt=?`, with the offending letter in `OPTARG` — your branches, your message, your status. Options stop at the first non-option word (`cmd`), which is how subcommands work.

### S06.3 — Why `local OPTIND`
- **Purpose.** See the bug you get when a function forgets to reset the option index.
- **Exact action.**
  ```bash
  parse2() {
    local n=10 opt                       # OPTIND deliberately NOT local
    while getopts ":n:" opt; do case "$opt" in n) n="$OPTARG" ;; esac; done
    shift $((OPTIND-1)); printf 'n=%s rest=%s\n' "$n" "$*"
  }
  parse2 -n 1 a
  parse2 -n 2 b
  ```
- **Expected observation (observed).**
  ```text
  n=1 rest=a
  n=10 rest=b
  ```
- **Verification.** The second call *ignores* `-n 2`.
- **Recovery.** Both lines correct → your shell had a fresh `OPTIND` by coincidence; run the two calls again in the same shell and the second will misbehave.
- **Evidence / next state.** **Why:** `OPTIND` is a global that remembers where the last `getopts` stopped (`3` after the first call), so the second call starts *past* its options. `local OPTIND` in every function that parses options — the S06.2 `parse` has it — resets it to 1 per call.

### S06.4 — Read a file or stdin
- **Purpose.** Make a tool that works both as `tool FILE` and as `producer | tool`.
- **Exact action.**
  ```bash
  read_input() { if [[ $# -ge 1 ]]; then cat -- "$1"; else cat; fi; }
  printf 'line1\nline2\n' > in.txt
  read_input in.txt | wc -l | tr -d ' '
  printf 'piped\n' | read_input
  printf 'x\n' > ./-n; read_input -n; rm -f ./-n      # a file literally named "-n"
  ```
- **Expected observation (observed).**
  ```text
  2
  piped
  x
  ```
- **Verification.** Three lines.
- **Recovery.** The third command hangs → you wrote `cat "$1"` without `--`: `cat` took `-n` as an *option* (number lines) and is waiting on stdin — press Ctrl-C, add the `--`. `read_input in.txt` hangs → the `$#` test is inverted.
- **Evidence / next state.** **Why `--`:** everything after `--` is a file name, never an option — the standard way to protect a tool from arguments that start with `-`. `logsleuth` and M09's `stackctl` read input exactly like this; M07 adds the temp-file trick that lets stdin be read twice.

### S06.5 — Exit codes are the API
- **Purpose.** Give distinct codes to distinct outcomes so callers can branch.
- **Exact action.**
  ```bash
  usage() { printf 'usage: tool [-n N] <count|top> [FILE]\n'; }
  main() {
    case "${1:-}" in
      count|top) echo "ok: $1"; return 0 ;;
      '')        usage >&2; return 2 ;;
      *)         printf 'unknown command: %s\n' "$1" >&2; return 2 ;;
    esac
  }
  main count; echo "status=$?"
  main frob;  echo "status=$?"
  main;       echo "status=$?"
  main frob 2>/dev/null || echo "caller saw failure (status $?)"
  cd /course && bash logsleuth/bin/logsleuth -Q top /dev/null; echo "status=$?"
  bash logsleuth/bin/logsleuth summary /nope; echo "status=$?"
  ```
- **Expected observation (observed).**
  ```text
  ok: count
  status=0
  unknown command: frob
  status=2
  usage: tool [-n N] <count|top> [FILE]
  status=2
  caller saw failure (status 2)
  [error] unknown option -Q (try: logsleuth -h)
  status=2
  [error] cannot read log file: /nope
  status=1
  ```
- **Verification.** Eleven lines; usage errors are `2`, the missing file is `1`.
- **Recovery.** `status=1` for `frob` → you wrote `exit 1`/`return 1` in the `*)` branch; the course reserves 1 for *runtime* failures. Usage text not shown → `usage` was sent to stderr and you ran with `2>/dev/null`; that is correct behavior for the third call (the text *is* on stderr by design).
- **Evidence / next state.** **The map every tool in this course uses:** `0` ok · `1` runtime failure (a file you cannot read) · `2` usage error (bad option, unknown command, missing argument) · tool-specific codes above that (`logsleuth bruteforce` → `3` when an attacker is found). A caller writes `logsleuth bruteforce auth.log || alert` and never parses text.

### S06.6 — Required inputs and defaults, the program's way
- **Purpose.** Three one-line idioms that every Course 1/2 script uses at the top: fail with a usage message when a required argument is missing, give an environment variable a default, and trim a prefix from it. (SK-07)
- **Exact action.**
  ```bash
  cd /tmp && printf '#!/usr/bin/env bash\nset -uo pipefail\nT="${1:?usage: replica-check.sh user@cloud-ip}"\necho "target=$T"\n' > rc.sh
  bash rc.sh; echo "status=$?"
  bash rc.sh ubuntu@203.0.113.10; echo "status=$?"
  bash -c ': "${STAGING:=https://staging.secmlops.com}"; HOST="${STAGING#https://}"; echo "STAGING=$STAGING HOST=$HOST"'
  STAGING=https://test.secmlops.com bash -c ': "${STAGING:=https://staging.secmlops.com}"; HOST="${STAGING#https://}"; echo "STAGING=$STAGING HOST=$HOST"'
  bash -c 'echo "${X:-fallback}"; echo "[${X-}]"; : "${X:=fallback}"; echo "[$X]"'
  cd /course && sed -n '5,6p' program/scripts/replica-check.sh && sed -n '2,4p' program/ci/validate_unauth.sh
  ```
- **Expected observation (observed).**
  ```text
  rc.sh: line 3: 1: usage: replica-check.sh user@cloud-ip
  status=1
  target=ubuntu@203.0.113.10
  status=0
  STAGING=https://staging.secmlops.com HOST=staging.secmlops.com
  STAGING=https://test.secmlops.com HOST=test.secmlops.com
  fallback
  []
  [fallback]
  set -uo pipefail
  T="${1:?usage: replica-check.sh user@cloud-ip}"; KEY="${SSH_KEY:-$HOME/.ssh/secmlops}"
  set -uo pipefail
  : "${STAGING:=https://staging.secmlops.com}"
  HOST="${STAGING#https://}"
  ```
- **Verification.** The first run aborts with the usage text and `status=1` before `echo` ever runs; the second prints the target. The last five lines are the real scripts — the idioms you just typed, verbatim.
- **Recovery.** `status=127` instead of `1` → you ran the `${1:?…}` line with `bash -c` and no script file; inside a script the status is 1 (observed both ways). `STAGING=` printed empty → you wrote `${STAGING:-…}` without the leading `: `; `:-` only *expands* a default, `:=` *assigns* it. `HOST` still has `https://` → the `#` pattern did not match (check the exact prefix, including `//`).
- **Evidence / next state.** **`${1:?message}`** — expand `$1`, or print `message` to stderr and exit 1 if it is unset or empty: a one-line required-argument check, stricter than S06.5's `case` because it fires even before `getopts`. **`: "${VAR:=default}"`** — the `:` builtin does nothing but *evaluates its arguments*, so the expansion runs and `VAR` is **assigned** the default when it was unset or empty; `${VAR:-default}` would only have used the default once, without saving it. **`${VAR#prefix}`** — M01's shortest-prefix removal, here turning a URL into a host name for `nmap`. **The program's own practice:** Course 1's `scripts/replica-check.sh` opens with exactly line 6 above; Course 2's `ci/validate_unauth.sh` defaults `STAGING` the same way, and the finished `ci/deploy.sh` opens with `: "${KUBE_CONTEXT:=staging}"` so one script serves staging and production. **Caution:** `:=` cannot assign to positional parameters (`${1:=x}` → `$1: cannot assign in this way`, observed), which is why required *arguments* use `:?` and optional *settings* use `:=`.

---

## Worked demonstration (10 min)

```bash
cd /course
bash labs/lab6-arguments/lab.sh
```
**Expected observation (observed).** `---- lab6: 21 passed, 0 failed ----`. It shows
`$1`/`$#`/`shift` and `"$@"` keeping a spaced argument whole; a `getopts` parser
handling `-n 5`, bundled `-v -n 3`, stopping at the first non-option, and
catching a missing argument (`:`) and an unknown option (`\?`); a reader that
takes a file or stdin (140 lines either way); an exit-code map `0/1/2`; then
the real tool — `logsleuth -V`, `help`, `-n 2 top`, `-f path top`, stdin input,
and three deliberate mistakes (`-Q`, `-n abc`, `-f bogus`) all rejected with
status 2 and a clear message.

---

## LAB-06 — Your exercise (graded as A-07) — 55 min

| Field | Value |
|---|---|
| Location | `labs/lab6-arguments/exercise/` (read `TASK.md`) |
| Starting assets | `starter/cli.sh` (`parse_opts` with the loop commented as a `# TODO`; `read_input` printing `FIXME`), `grade.sh` |
| Allowed resources | This module, documentation, AI assistance (disclosed); **not** `solution/` |
| Deliverables | `work/cli.sh` passing the grader; `work/REFLECTION.md` with R1 and R2 |
| Acceptance | `bash grade.sh` ends `---- lab6: 7 passed, 0 failed ----`; both reflections present |

**Procedure.**
1. `cd labs/lab6-arguments/exercise && bash grade.sh`. **Observed on the starter:** `---- lab6: 0 passed, 7 failed ----`.
2. Edit `work/cli.sh`:
   - `parse_opts`: the S06.2 loop — `":n:v"`, branches for `n`, `v`, `:` and `\?` (the error branches print to stderr and `return 2`), then `shift $((OPTIND-1))` and the `n=… v=… rest=…` line. Keep `local … OPTIND` (S06.3).
   - `read_input`: S06.4, with `cat -- "$1"`.
3. Re-run until **`---- lab6: 7 passed, 0 failed ----`** (observed with the reference). The checks: defaults `n=10 v=0 rest=file.log`; `-n 5 -v` parsed; options stop at the first non-option (`rest=a.log -v`); `-n` without a value fails; `-z` fails; `read_input` reads a named file; `read_input` reads stdin.
4. `work/REFLECTION.md`:
   - **R1.** What does the leading `:` in `":n:v"` change about how `getopts` reports errors, and what do your `:` and `\?` branches each receive in `OPTARG`?
   - **R2.** Why does the course send usage/error text to **stderr** and exit with **2** (not 1) for a usage mistake? Describe one caller that depends on each half of that rule.

**Learner-visible rubric (A-07).** *Pass* = `0 failed` **and** both reflections name the mechanism. Unlimited attempts.

**Hints.** H1: if you see bash's own `illegal option -- z` text instead of yours, the leading `:` is missing from the optstring. H2: `rest=` is `"$*"` *after* the `shift`. H3: `read_input` must not print anything of its own — `cat` is the whole body.

**Reset.** `rm -rf work && bash grade.sh`.

---

## Knowledge checks (predict, then run)

1. What does the leading `:` in `":n:v"` change?
2. After the `getopts` loop, what does `shift $((OPTIND-1))` leave in `$1`?
3. Why does `parse -v cmd -n 9` leave `-n 9` in `rest`?
4. Why must a function that uses `getopts` declare `local OPTIND`?
5. `logsleuth -Q top FILE` exits 2 and `logsleuth summary /nope` exits 1. Why different codes?

---

## In the SecMLOps Program
Exit codes as an API is the program's contract: every `ci/*.sh` stage ends with a `…-PASS` line **and** exit 0, or `exit 1`; the CI platform reads the code, humans read the line (S06.5's two channels). `ci/sarif_gate.sh` takes its files as positional parameters (`for f in "$@"`); `scripts/replica-check.sh` requires one with `T="${1:?usage: replica-check.sh user@cloud-ip}"` — the `${var:?message}` form that fails fast with a usage line. `stackctl -e ENV COMMAND` in M09 is `logsleuth`'s `getopts` + `case` with a different vocabulary; Course 1's `make <target>` is the same dispatcher expressed as a Makefile.

**Read the real thing (5 min).** Open `program/scripts/replica-check.sh` (Course 1) and `program/ci/deploy.sh` (Course 2). In `notes/M06-read.txt`: (a) list every input each script takes — positional, environment variable, file — and whether it is required or defaulted; (b) `deploy.sh` has no `${1:?…}`: where does its "required input" check actually happen, and what exit code does a missing `image.digest` produce under `set -euo pipefail`? Answers at the end of the page.

---

## Recap and transfer
`"$@"` to forward, `shift` to walk, `getopts ":…"` with your own `:`/`\?`
handling and `local OPTIND`, a file or stdin with `cat -- "$1"`, and codes
`0/1/2` as the contract. **Transfer:** M07 makes this command line safe to
schedule (clean exit under failure and signals); A-10 asks you to assemble all of
it into a tool of your own; M09's `stackctl` uses this exact front door —
`validate`/`plan`/`up`/`destroy` dispatched by `case`, usage errors at `2`, a
check failure at `3`.

---

## Self-check answers

1. Silent mode: `getopts` stops printing its own messages and instead hands you `opt=:` (missing argument) or `opt=?` (unknown option) with the letter in `OPTARG`, so *you* write the message and choose the status (observed: `error: -n needs an argument`, status 2).
2. The first non-option argument — `OPTIND` is the index of the next unparsed word, so dropping `OPTIND-1` words removes exactly the options consumed.
3. `getopts` stops at the first word that is not an option (`cmd`); everything after it is left for the command — that is what makes subcommands with their own arguments possible (observed: `rest=cmd -n 9`).
4. `OPTIND` is global and keeps the position where the previous `getopts` stopped; without `local OPTIND` the second call starts mid-way and ignores its options (observed: `n=10 rest=b`).
5. Two different failure *classes*: `2` means the caller made a usage mistake and should fix the command line; `1` means the command was fine but something at runtime failed (an unreadable file). A caller — or a cron job — can react differently to each.

**Read the real thing.** (a) `replica-check.sh`: `$1` required (`${1:?usage…}`), `SSH_KEY` defaulted to `$HOME/.ssh/secmlops`; it also reads the Vagrant lab and the cloud host over `ssh`. `deploy.sh`: no positional parameters; `versions.env` is *sourced* (required — a missing file aborts under `-e`; it supplies `IMAGE` and `COSIGN_VERIFY_FLAGS`), `KUBE_CONTEXT` defaults to `staging` and `APP_ENV` to `test` with `:=`, `GIT_SHA` and `API_URL` default inline with `:-`, and `image.digest`, `cosign.pub`, `k8s/serve.yaml` and the kubectl context are required files/contexts. (b) There is no explicit check: `DIGEST="$(cat image.digest)"` fails when the file is missing, and `set -e` turns that into an abort with `cat`'s status **1** — correct, but the message is `cat: image.digest: No such file or directory`, not a usage line. A `${…:?}`-style check would say what was expected; that is the difference between a script that stops and a script that explains.
