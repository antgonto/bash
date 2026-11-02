# M07 — Robustness: `set -e` edges, traps, temp files, locks
**FULL TRAINER EDITION · curriculum v2.0.0-draft · self-paced, no fixed duration**

> **TRAINER ONLY — about this edition.** Student text verbatim; trainer blocks inserted. IDs: S07.1–S07.6, LAB-07, A-08.
>
> **Prep (≈20 min).** `cd labs/lab7-robustness/exercise && rm -rf work && bash grade.sh` → **observed** `---- lab7: 2 passed, 4 failed ----`; `GRADE_TARGET="$PWD/solution" bash grade.sh` → **observed** `---- lab7: 6 passed, 0 failed ----`; `bash labs/lab7-robustness/lab.sh` → **observed** `---- lab7: 15 passed, 0 failed ----`. Confirm `flock --version` works in the learner image (util-linux). Expect `/tmp/lab7.*` directories to accumulate while learners work on the starter — that *is* the bug they are fixing; `rm -rf /tmp/lab7.*` between cohorts.
>
> **Trainer effort:** prep 20 min; A-08 review ≈ 6 min per learner (R1 and R2 both require an observation).
>
> **Facilitator pathway (optional 45-min session).** 0–10 min: S07.3 live — the three one-liners, predict before each. 10–20 min: S07.1 and S07.4 self-paced (S07.4 involves a background job and `kill`; warn that this is expected). 20–40 min: LAB-07. 40–45 min: debrief R1 aloud.


**Outcome LO-08.** You can make a script safe to schedule: you know the two
places `set -e` surprises people, you create temp files with `mktemp` and
remove them on *any* exit with a `trap` that preserves the real exit code, you
handle signals, and you serialize access to a shared resource with `flock`.

**What you'll build.** `worker.sh` — a script that never leaks its temp
directory and never corrupts its own exit code — in
`labs/lab7-robustness/exercise/` (graded as A-08).

**Prerequisite check.** A-07 passed. You use S00.7 (the strict-mode header),
S00.8 (exit codes), S04.3 (status vs output) and S06.5 (the `0/1/2` map).

---

## Activity context for S07.1–S07.6

| Field | Value |
|---|---|
| Execution context | Inside the course container (or fallback shell), in a scratch folder: `mkdir -p ~/bash-course-work/lab7 && cd ~/bash-course-work/lab7` |
| Starting state | `bash tools-check.sh` reports ready (`flock` from util-linux present) |
| Validation status | Every expected output in S07.1–S07.6 was **observed** in the authoring environment (bash 5.2.21, util-linux `flock`, procps `ps`; 2026-10-19, S07.6 on 2026-10-26); temp-directory names vary by run and are shown as `…` |

### S07.1 — The two sharp edges of `set -e`
- **Purpose.** Know exactly when strict mode does and does not abort — the cause of most "why did my script die?" questions. (SK-08)
- **Exact action.**
  ```bash
  bash -c 'set -e; if grep -q zzz <<<"abc"; then echo y; else echo n; fi'       # status consumed by if
  bash -c 'set -e; grep -q zzz <<<"abc" || echo "handled"; echo "still running"' # consumed by ||
  bash -c 'x=0; if (( x++ )); then echo t; else echo f; fi'                      # (( x++ )) with x=0
  bash -c 'set -e; x=0; (( x++ )); echo "not reached"'; echo "status=$?"
  bash -c 'set -e; x=0; (( ++x )); echo "x=$x"'
  ```
- **Expected observation (observed).**
  ```text
  n
  handled
  still running
  f
  status=1
  x=1
  ```
- **Verification.** Six lines; `not reached` never appears.
- **Recovery.** `not reached` printed → you typed `(( ++x ))` on the fourth line. `t` on the third → you started from `x=1`.
- **Evidence / next state.** **Edge 1:** `set -e` does **not** fire for a command whose status is *consumed* — by `if`, `while`, `&&`, `||`. That is a feature: it is how you handle expected failures. **Edge 2:** `(( x++ ))` evaluates to the *old* value, `0`, which is "false", so it returns status 1 and strict mode aborts; write `(( ++x ))` or `x=$(( x + 1 ))`.


> **TRAINER ONLY.** *Ask:* "Is edge 1 a bug or a feature?" *Expected:* "a feature — it is the only way to handle an expected failure under strict mode (`cmd || fallback`)." *Misconception:* `set -e` is error handling — repeat M00's guardrail: it is a *tripwire*, not a handler. *Observed detail worth showing:* `bash -c 'set -e; x=0; (( x++ )); echo "not reached"'` exits 1 with **no message at all** — the silent death is what makes this edge expensive to debug; M08's `set -x` is the diagnostic. *Grading relevance:* none directly; the capstone tools use `x=$(( x + 1 ))` and `(( ++x ))` only.

### S07.2 — `mktemp` + `trap … EXIT`: clean up on any exit
- **Purpose.** Create a temp directory that cannot collide with another run, and remove it whether the script succeeds or fails.
- **Exact action.**
  ```bash
  cat > exits.sh <<'EOF'
  #!/usr/bin/env bash
  set -euo pipefail
  d="$(mktemp -d)"
  trap 'rm -rf "$d"; echo "cleaned $d" >&2' EXIT
  echo "working in $d"
  exit "${1:-0}"
  EOF
  bash exits.sh 0; echo "status=$?"
  bash exits.sh 5; echo "status=$?"
  ```
- **Expected observation (observed; `…` is a random name).**
  ```text
  working in /tmp/tmp.…
  cleaned /tmp/tmp.…
  status=0
  working in /tmp/tmp.…
  cleaned /tmp/tmp.…
  status=5
  ```
- **Verification.** `cleaned` appears after both runs; the second ends with `status=5`.
- **Recovery.** No `cleaned` line → the `trap` line is missing or spelled `EXIT` wrongly (it is case-sensitive). `mktemp: too few X's` → you added a template without enough `XXXXXX`.
- **Evidence / next state.** **Why:** `mktemp -d` creates a uniquely named directory atomically — two runs never share one. `trap 'commands' EXIT` runs the commands when the script ends *for any reason*: normal exit, `exit N`, or a `set -e` abort. The directory is gone even on failure; that is what "no temp leak" means.


> **TRAINER ONLY.** *Ask:* "What is wrong with `tmp=/tmp/work`?" *Expected:* "collisions between runs/users, and a predictable name an attacker can pre-create (symlink) — `mktemp` avoids both." `mktemp -d "${TMPDIR:-/tmp}/lab7.XXXXXX"` (the exercise's form) respects a user's `TMPDIR` and gives a recognizable prefix for the grader's leak check. *Misconception:* the EXIT trap does not run on `exit N` — it does (observed `status=5` with `cleaned`). *Also observed:* the trap runs on a `set -e` abort — `bash -c 'set -e; trap "echo bye" EXIT; false; echo no'` prints `bye`.

### S07.3 — The EXIT-trap status gotcha
- **Purpose.** Keep the script's real exit code even when the cleanup itself fails.
- **Exact action.**
  ```bash
  bash -c 'trap "false" EXIT; exit 0';        echo "no -e: status=$?"
  bash -c 'set -e; trap "false" EXIT; exit 0'; echo "with -e: status=$?"
  bash -c 'set -e; trap "rc=\$?; rm -rf /nonexistent-xyz; exit \$rc" EXIT; exit 3'; echo "capture-and-reexit: status=$?"
  ```
- **Expected observation (observed).**
  ```text
  no -e: status=0
  with -e: status=1
  capture-and-reexit: status=3
  ```
- **Verification.** `0`, then `1`, then `3`.
- **Recovery.** `capture-and-reexit: status=1` → the `\$?` must be captured as the **first** thing in the trap; anything before it changes `$?`. `status=0` on the third → you escaped `\$rc` wrongly inside the double quotes (copy the line exactly).
- **Evidence / next state.** **The rule:** under `set -e`, a failing command *inside* the EXIT trap clobbers the exit code to `1` — your meaningful `exit 3` is lost. **The fix the course uses everywhere:** `trap 'rc=$?; cleanup; exit "$rc"' EXIT` — capture the code first, clean up, re-exit with the real code. This is why `logsleuth bruteforce` can promise its `3`.


> **TRAINER ONLY — this is the module's central idea; make every learner run the three lines.** *Why the escaping in the third line:* the trap string is inside a double-quoted `bash -c` argument, so `\$?` and `\$rc` must survive the outer quoting — in a script file the line is simply `trap 'rc=$?; cleanup; exit "$rc"' EXIT` (single quotes; the shellcheck `SC2154` disable comment exists because shellcheck cannot see that `rc` is assigned inside that string). *Observed:* `logsleuth/bin/logsleuth` uses exactly `trap 'rc=$?; cleanup; exit "$rc"' EXIT`, and `lib/util.sh`'s `cleanup` ends in `return 0` as a second line of defense. *Ask:* "Why capture *first*?" *Expected:* "`$?` is overwritten by every command; the first thing the trap does must be to save it."

### S07.4 — Signals: Ctrl-C and `kill` must clean up too
- **Purpose.** Make the cleanup hold when the script is interrupted, not only when it ends on its own.
- **Exact action.**
  ```bash
  cat > w.sh <<'EOF'
  #!/usr/bin/env bash
  set -euo pipefail
  d="$(mktemp -d "${TMPDIR:-/tmp}/demo.XXXXXX")"
  # shellcheck disable=SC2154
  trap 'rc=$?; rm -rf "$d"; exit "$rc"' EXIT INT TERM
  echo "$d" > "$1"                 # publish the temp path so we can watch it
  while true; do sleep 0.2; done   # a long-running job
  EOF
  bash w.sh marker & wpid=$!
  sleep 1
  tmpdir="$(cat marker)"; test -d "$tmpdir" && echo "temp dir exists while running"
  kill -TERM "$wpid"; wait "$wpid" 2>/dev/null
  test -d "$tmpdir" && echo "LEAKED" || echo "temp dir gone after SIGTERM"
  ```
- **Expected observation (observed).**
  ```text
  temp dir exists while running
  temp dir gone after SIGTERM
  ```
- **Verification.** The second line says `gone`; `ls /tmp/demo.*` shows nothing.
- **Recovery.** `LEAKED` → the trap line is missing or does not name `TERM`; `kill` the worker (`kill "$wpid"`) and `rm -rf /tmp/demo.*` before retrying. `marker: No such file` → you ran `cat marker` before the worker started; increase the `sleep`.
- **Evidence / next state.** **Why name the signals:** a trap on `INT` (Ctrl-C) and `TERM` (`kill`) turns the signal into a normal `exit`, which runs the EXIT cleanup. The one-line `trap '…' EXIT INT TERM` is the course's standard form (and what the A-10 rubric looks for). Two observed facts about it: bash runs an EXIT-only trap on `kill` as well (status `143` = 128 + 15), while a Ctrl-C aimed only at the shell during a child command can be swallowed — naming `INT` fixes that; and because the handler re-uses `$?`, a worker killed this way exits with the last command's status (`0` here). When the status *after a signal* matters, a tool adds `trap 'exit 130' INT` and `trap 'exit 143' TERM` beside the EXIT cleanup (observed: `130`/`143`, directory still removed).


> **TRAINER ONLY — the full observed picture (2026-10-19, bash 5.2.21), because the v1 wording was looser than the facts.** (1) An **EXIT-only** trap *does* run when the shell is killed with `SIGTERM` or `SIGHUP`: the dir was removed and the worker exited `143` / `129`. (2) A `SIGINT` sent **only to the shell** (`kill -INT <pid>`) while it waits for a child that then exits normally is swallowed — with an EXIT-only trap the worker **kept running** (observed; a real Ctrl-C hits the whole process group, so the child dies of INT too and bash then acts on it). Naming `INT` in the trap makes the shell react in both cases. (3) The one-line `trap 'rc=$?; …; exit "$rc"' EXIT INT TERM` reports the status of the last *completed* command after a signal — observed `0` after `kill -TERM`; the EXIT-only form reports `143`. (4) The status-preserving form — EXIT cleanup plus `trap 'exit 130' INT` and `trap 'exit 143' TERM` — cleaned up **and** reported `130`/`143` (observed). *Course decision:* teach the one-line form as the standard because LAB-07's reference and A-10's grader (`grep -cE '^trap '` must equal **1**) expect a single trap line; the student text states the `0`-status side effect plainly and names the three-trap alternative. **v1 wording corrected:** `logsleuth` traps **EXIT only**; the lab's worker adds `INT TERM`. The v1 Part 7 page and `TASK.md` said "the exact trap idiom in logsleuth" — both now say "the capture-and-re-exit idiom logsleuth uses (on EXIT; the worker adds INT TERM)". *Clean-up tip for the room:* if anyone's worker is still running, `pkill -f w.sh` and `rm -rf /tmp/demo.*`.

### S07.5 — `flock`: one writer at a time
- **Purpose.** Protect a shared file from two processes writing at once — the guard M09's `stackctl` puts around `up` and `destroy`.
- **Exact action.**
  ```bash
  : > out.txt
  writer() { local i; for i in $(seq 1 200); do
    flock out.lock bash -c 'printf "%s\n" "$1" >> "$2"' _ "line-$i-$3" out.txt
  done; }
  writer a 1 A & writer b 2 B & wait
  wc -l < out.txt; grep -c '^line-[0-9]*-[AB]$' out.txt
  ( flock -n out.lock sleep 2 ) & sleep 0.3
  flock -n out.lock echo "got the lock" || echo "busy: someone else holds the lock (status $?)"
  wait
  ```
- **Expected observation (observed).**
  ```text
  400
  400
  busy: someone else holds the lock (status 1)
  ```
- **Verification.** Both counts `400`; the last line says `busy`.
- **Recovery.** `flock: command not found` → install `util-linux` (present in the container). Counts below 400 → a typo in the pattern; `cat out.txt | head` to look.
- **Evidence / next state.** **Why:** `flock LOCKFILE command` runs `command` only while holding an exclusive lock on `LOCKFILE`; a second `flock` on the same file waits — or, with `-n`, gives up immediately with status 1. Two writers appending 200 lines each produced exactly 400 intact lines. In M09 the lock is `envs/<env>.lock`, so two `stackctl up dev` runs cannot race.


> **TRAINER ONLY.** *Ask:* "What does the lock file *contain*?" *Expected:* "nothing — it is only a name the kernel attaches the lock to." *Misconception:* `flock` prevents the other process from *reading* — it only serializes other `flock` callers; a process that ignores the lock is not blocked. *Honesty note:* do **not** claim the unlocked version visibly corrupts here — for short `O_APPEND` writes the kernel usually keeps lines intact anyway; the demonstration shows the *idiom* and the `-n` behavior (observed `busy … status 1`), and M09 is where the lock earns its keep (`stackctl up dev` twice at once would otherwise race `docker compose`). *Preview:* `flock envs/dev.lock stackctl …` vs the in-script `exec 9>"$lock"; flock -n 9 || die` form — the course uses the command form for readability.

### S07.6 — Secrets pass through the shell: where they leak, and the four habits
- **Purpose.** From Course 2 Chapter 2 on, your scripts hold tokens and signing keys (`BAO_TOKEN`, `COSIGN_PASSWORD`, `cosign.key`). The shell leaks them in four ordinary ways; each one is visible, and each has a habit that closes it.
- **Exact action.**
  ```bash
  bash -c 'sleep 30; :' fake-login --password=hunter2 &
  ps -o args= -p $!                                  # 1. the argument list is public
  kill $!; wait $! 2>/dev/null
  export API_TOKEN=hunter2
  bash -c 'env | grep ^API_TOKEN'                    # 2. the environment is inherited by every child
  bash -xc 'curl -s -m 1 -o /dev/null -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:1/' 2>&1 | grep -c hunter2
  bash -xc 'set +x; curl -s -m 1 -o /dev/null -H "Authorization: Bearer $API_TOKEN" http://127.0.0.1:1/; set -x; echo done' 2>&1 | grep -c hunter2
  umask 077; printf 'FAKE-KEY-MATERIAL\n' > cosign.key; stat -c '%a %n' cosign.key     # 4. a key file's permissions
  umask 022; printf 'FAKE\n' > other.key; stat -c '%a %n' other.key
  chmod 600 other.key; stat -c '%a %n' other.key
  rm -f cosign.key other.key
  unset API_TOKEN; bash -c 'echo "token now: [${API_TOKEN:-}]"'
  printf 'hunter2\n' | { read -r pw; echo "read ${#pw} chars, never on a command line"; }
  ```
- **Expected observation (observed).**
  ```text
  bash -c sleep 30; : fake-login --password=hunter2
  API_TOKEN=hunter2
  1
  0
  600 cosign.key
  644 other.key
  600 other.key
  token now: []
  read 7 chars, never on a command line
  ```
- **Verification.** `ps` prints the whole command line including `--password=hunter2`; the child sees `API_TOKEN=hunter2`; the trace leaks the token once (`1`) and not at all when `set +x` brackets the call (`0`); the permissions read `600`, `644`, `600`; after `unset` the child sees nothing; the last line reports `7` characters.
- **Recovery.** `ps` prints nothing → the background job had already exited (rerun; `sleep 30` keeps it alive). `ps: unknown option` → the fallback shell has a BusyBox `ps`; use `cat /proc/$!/cmdline | tr '\0' ' '`. The fifth line prints `1` instead of `0` → `set +x` is after the `curl`, not before. `stat -c` unknown → BSD `stat` (macOS without the GNU tools): `stat -f '%Lp %N'`.
- **Evidence / next state.** **The four leaks and the four habits.** (1) **Arguments are public:** every user on the machine can `ps` them, and the shell's history file keeps them — so a secret never goes on a command line. Course 2 Labs 8.1 and 9.1 run `docker login … -p "$(bao kv get …)"`; the password is in `docker`'s argument list for the length of the call, and `docker login` says so itself (`WARNING! Using --password via the CLI is insecure`). The habit is `--password-stdin`: `bao kv get -field=robot_token … | docker login … -u "$USER" --password-stdin` — the last line above is the same move. (2) **The environment is inherited** by every child, including ones you did not think about (`curl`, an editor, a scanner that phones home its environment on crash). The habit is scope: a one-shot `TOKEN=… cmd` (S01.7) instead of `export`, and `unset` the moment you are done — Lab 10.1 does exactly `bao kv put … client_secret="$SECRET" …; unset SECRET`. (3) **Traces print values:** `set -x` (M08 S08.3) and a CI platform's debug mode show every expanded argument; the habit is `set +x` around the sensitive call, or never tracing with a real token. (4) **Key files have permissions:** `bao kv get -field=key … > cosign.key` creates the file with your `umask` — `644` by default, readable by everyone on a shared runner; the habit is `umask 077` before (or `chmod 600` right after), and `rm -f cosign.key` as soon as the signature exists, which is what `ci/release.sh` and `ci/sign_model.sh` do. A `trap 'rm -f cosign.key' EXIT` (S07.2) makes the removal survive a failed signature too.


> **TRAINER ONLY (added Batch 7, 2026-10-26; observed, bash 5.2, procps `ps`, GNU `stat`; the `docker login` warning text observed with Docker CLI 29.x).** *Why this step exists:* Course 2 is a security program whose Chapter 2 is *Platforms, Identity & Secrets*, yet the shell-level hygiene was taught nowhere; the audit found `docker login -u admin -p "$(bao kv get …)"` in Labs 8.1 and 9.1 (argv leak), `export BAO_TOKEN=…` persisting for whole sessions (Labs 2.1, 3.1), and `bao kv get -field=key … > cosign.key` with a default umask (Labs 6.1, 8.1, 8.2). *Ask first:* "Where could `hunter2` be read from after `fake-login --password=hunter2` runs?" *Expected, in order:* `ps`, `~/.bash_history`, `/proc/PID/cmdline`. *Live:* run the `ps` line while a second terminal does `ps -ef | grep fake-login` as another user if the lab has one — the point lands harder. *Trace line:* a learner who gets `1` for the `set +x` variant has the `set +x` after the `curl`; make them read the order. *Platform:* BSD `stat` differs (`-f '%Lp %N'`); Git Bash `ps` shows only its own processes — both noted in Recovery. *Do not* suggest `history -c` as the fix; the fix is never to put the secret there. *Report upstream:* the two Course 2 labs should move to `--password-stdin`; the finding is listed in the manifest.

---

## Worked demonstration (10 min)

```bash
cd /course
bash labs/lab7-robustness/lab.sh
```
**Expected observation (observed).** `---- lab7: 15 passed, 0 failed ----`. It proves
the two `set -e` edges, cleanup on success and on failure, the status gotcha
(`0` without `-e`, `1` with `-e`, `3` with capture-and-re-exit), a worker that
is killed with SIGTERM and leaves no temp dir, two `flock`ed writers producing
400 intact lines, and the real tool: three `logsleuth` runs on stdin leave zero
temp files, `bruteforce`'s exit `3` survives the cleanup trap, and the tool
still runs under a hostile `IFS`.


> **TRAINER ONLY — what `lab.sh` asserts (15 checks, observed).** `if` consumes a failure under `-e`; `(( x++ ))` from 0 is false; `(( ++x ))` safe; cleanup on success and failure (`cleaned`); no `-e` → trap failure leaves 0; `-e` → clobbers to 1; capture-and-re-exit → 3; a background worker's dir exists, then is gone after `SIGTERM`; two `flock`ed writers → 400 lines, all intact; `logsleuth`: three stdin runs leave zero `/tmp/logsleuth.*` files, `bruteforce` exits 3 through the trap, and the tool runs under `IFS=x`. The signal check depends on timing (`seq 1 50` polls for the marker); on a very slow machine it can report FAIL spuriously — rerun before investigating.

---

## LAB-07 — Your exercise (graded as A-08) — 50 min

| Field | Value |
|---|---|
| Location | `labs/lab7-robustness/exercise/` (read `TASK.md`) |
| Starting assets | `starter/worker.sh` (creates the temp dir and publishes it; **no trap**, hard-coded `exit 0`), `grade.sh` |
| Allowed resources | This module, documentation, AI assistance (disclosed); **not** `solution/` |
| Deliverables | `work/worker.sh` passing the grader; `work/REFLECTION.md` with R1 and R2 |
| Acceptance | `bash grade.sh` ends `---- lab7: 6 passed, 0 failed ----`; both reflections present |

**The contract.** `worker.sh <marker> [exitcode]` creates a temp dir and writes its
path to `<marker>`, removes the dir on **any** exit or signal, and exits with
`<exitcode>` (default 0) — preserved **through** the cleanup trap.

**Procedure.**
1. `cd labs/lab7-robustness/exercise && bash grade.sh`. **Observed on the starter:** `---- lab7: 2 passed, 4 failed ----` — exit 0 happens to be "preserved" and the file is shellcheck-clean, but the temp dir leaks and exit 3 is ignored.
2. Edit `work/worker.sh`: add the S07.4 trap line under the `# shellcheck disable=SC2154` comment (keep that comment — `rc` is assigned inside the trap string), and change the last line to `exit "${2:-0}"`.
3. Re-run until **`---- lab7: 6 passed, 0 failed ----`** (observed with the reference). The checks: exit 0 preserved; temp dir removed after exit 0; exit 3 preserved through the trap; temp dir removed after exit 3; three runs leave no `lab7.*` dirs in `/tmp`; shellcheck-clean.
4. `work/REFLECTION.md`:
   - **R1.** Why does the trap capture `$?` into `rc` *before* `rm -rf`, and what would the grader's "exit 3 is preserved" check see if a cleanup command failed under `set -e`? Quote what you observed in S07.3.
   - **R2.** The trap names `EXIT INT TERM`. Say what each name covers, and what you observed in S07.4 about a worker killed with `kill -TERM`.

**Learner-visible rubric (A-08).** *Pass* = `0 failed` **and** both reflections name the mechanism with an observation. Unlimited attempts.

**Hints.** H1: the whole fix is two lines — one `trap`, one `exit`. H2: `rc=$?` must be the first command inside the trap string. H3: `ls /tmp/lab7.*` between runs shows you whether you are still leaking.

**Reset.** `rm -rf work && bash grade.sh` (and `rm -rf /tmp/lab7.*` if an earlier version leaked).


> **TRAINER ONLY — complete solution (reference `solution/worker.sh`, observed 6/6):**
> ```bash
> #!/usr/bin/env bash
> # Lab 7 solution — signal-safe temp cleanup with a code-preserving trap.
> # Contract:  worker.sh <marker> [exitcode]
> set -euo pipefail
>
> d="$(mktemp -d "${TMPDIR:-/tmp}/lab7.XXXXXX")"
> # shellcheck disable=SC2154  # rc is assigned inside the trap string, then used
> trap 'rc=$?; rm -rf "$d"; exit "$rc"' EXIT INT TERM   # INT/TERM funnel into EXIT
>
> printf '%s\n' "$d" > "$1"     # publish our temp dir so the grader can watch it
>
> exit "${2:-0}"
> ```
> *Acceptable variations:* `trap 'rc=$?; rm -rf "$d"; exit "$rc"' EXIT` alone **passes** (the grader sends no signals) — accept it, but R2 must still explain `INT TERM`; the three-trap status-preserving form passes too (the grader does not count trap lines; A-10's does — say so). `exit "$2"` without the `:-0` default **passes the grader** (every grader call supplies a code) but breaks the contract's default: called with one argument it dies under `set -u` with `$2: unbound variable`, status 1 (observed) — run `bash work/worker.sh "$(mktemp)"` by hand to catch it. Removing the `# shellcheck disable=SC2154` line makes shellcheck warn `rc is referenced but not assigned` and the quality check FAILs (observed 5/6).
>
> **Grading procedure (≈6 min/learner).** 1) `GRADE_TARGET=/path/to/their/work bash labs/lab7-robustness/exercise/grade.sh` → require `---- lab7: 6 passed, 0 failed ----`; also glance at `ls /tmp/lab7.*` — it should list nothing. 2) Reflections:
> - **R1 — Met:** `$?` is overwritten by every command, so it must be saved first; under `set -e` a failing cleanup command inside the trap would abort the trap with status 1 and the caller would see `1` instead of `3`; quotes the observed `with -e: status=1` / `capture-and-reexit: status=3`. **Strong:** adds that `exit "$rc"` is what re-asserts the saved code, or that `logsleuth` guards twice (capture + `cleanup` ending in `return 0`). **Not met:** "to keep the exit code" with no mechanism or no observation.
> - **R2 — Met:** `EXIT` = any normal or `set -e` exit; `INT` = Ctrl-C; `TERM` = `kill`'s default; naming the signals makes them run the same handler, which exits and so fires the cleanup; reports the observed `temp dir gone after SIGTERM`. **Strong:** notes one of the observed subtleties — the handler's status is the last command's (`0`), or that bash runs an EXIT-only trap on TERM anyway — and still justifies the course form. **Not met:** "to catch all signals" (SIGKILL cannot be trapped; HUP is not listed) or no observation.
>
> 3) Record `A-08 PASS` only with 6/6 and both reflections ≥ Met.
>
> **Calibration.** *R1 Met:* "The first thing in the trap is `rc=$?` because `$?` only holds the exit code until the next command runs. If `rm -rf` failed under `set -e`, the trap would stop and bash would exit 1 — in S07.3 I saw `status=1` for exactly that, and `status=3` once the code was captured and re-exited." *R1 Not met:* "You save the return code so you can return it." (restates, no mechanism, no observation).
>
> **Model feedback (Not yet):** "`exit 3 is preserved through the trap` got `0`: your last line is still `exit 0`; it must be `exit "${2:-0}"`." / "`temp dir removed after exit 0` FAIL: the trap line is still a comment." **Remediation:** S07.2–S07.4. **Equivalent reassessment:** same grader; **R1'** "Why does `mktemp -d` take a template ending in `XXXXXX`?" (Met: the X's are replaced by random characters so each run gets a unique, unpredictable name) and **R2'** "Why does the grader run the worker three times and count `/tmp/lab7.*` before and after?" (Met: a leak shows up as a growing count; three runs make a single accidental pass unlikely).
>
> **Evidence handling / reset:** keep grader output and `REFLECTION.md`; learners `rm -rf work /tmp/lab7.*`.

---

## Knowledge checks (predict, then run)

1. Under `set -e`, does `if grep -q x file; then …; fi` abort when `grep` finds nothing?
2. Why does `(( x++ ))` abort a strict-mode script when `x` is 0, while `(( ++x ))` does not?
3. A script does `exit 3` and its EXIT trap runs `rm -rf "$d"`, which fails. Under `set -e`, what status does the caller see — with and without `rc=$?` capture?
4. What does `flock -n lockfile cmd` do when another process holds the lock?
5. Why create temp files with `mktemp` rather than a fixed name like `/tmp/work`?
6. Course 2 runs `docker login harbor… -u admin -p "$(bao kv get -field=password …)"`. Which of S07.6's four leaks is that, and what is the fix?


> **TRAINER ONLY — answers and distractors.**
> 1. No — consumed status (observed `n`). Tempting: "yes, grep failed" — the `if` consumed it.
> 2. `(( x++ ))` evaluates to the old value 0 → status 1; `(( ++x ))` to 1 → status 0 (observed). Tempting: "both increment, so both are fine" — they do both increment; the *status* differs.
> 3. `3` with capture; `1` without (observed). Tempting: `0` — the trap's failure under `-e` is the whole gotcha.
> 4. Exits 1 immediately without running `cmd` (observed `busy … status 1`). Tempting: "waits" — that is `flock` without `-n`.
> 5. Uniqueness and safety: no collisions between concurrent runs, no predictable path to hijack, and the trap knows exactly what to remove. Tempting: "`/tmp` is cleaned on reboot anyway" — leaks between reboots still fill disks and expose data.
> 6. Leak 1 (argv): the expanded password is visible to `ps` for the call's duration (observed with `--password=hunter2`); use `--password-stdin` fed by a pipe. Tempting: "it's inside `$( )`, so it's hidden" — the substitution happens *before* `docker` starts, and the result is an ordinary argument.

---

## In the SecMLOps Program
Every `ci/*.sh` in Course 2 starts with `set -euo pipefail`; `ci/validate_unauth.sh` uses `set -uo pipefail` and `|| true` on every scanner call on purpose — the scanners' non-zero exits are findings, not failures, so the script decides at the end (S07.1's edges, chosen deliberately). `ci/release.sh` writes a signing key to `cosign.key` and `rm -f`s it at the end — read it with today's eyes: an abort between those lines leaves the key on disk, which is what an EXIT trap is for. Course 1's `scripts/replica-check.sh` creates `tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT` on one line — it did *not* until this course's alignment audit found the missing trap (fixed upstream 2026-11-02). `stackctl` (M09) does both the right way.

**Read the real thing (5 min).** Open `program/ci/validate_unauth.sh` and `program/scripts/replica-check.sh` (both shipped read-only). In `notes/M07-read.txt`: (a) `replica-check.sh` sets `trap 'rm -rf "$tmp"' EXIT` on the *same line* as `mktemp -d`. Which S07 habit is that, when exactly would the directory be left behind without it (hint: the script has no `-e`), and why does the trap belong on the same line rather than, say, before the final `diff`? (b) `validate_unauth.sh`'s `sarif_gate` distinguishes `MISSING`, `UNREADABLE` and `CRITICAL`. The version it replaced was one line: `[ -f "$s" ] && jq -e '…' "$s" >/dev/null && { echo "CRITICAL in $s"; exit 1; }`. Which case did that line get wrong, and what did the stage print in that case? Answers at the end of the page.

---

## Recap and transfer
Expected failures are *consumed*; `(( ++x ))` not `(( x++ ))`; `mktemp` + a
code-preserving `trap` on `EXIT INT TERM`; `flock` around anything that must not
run twice at once. **Transfer:** M08 tests these guarantees (zero temp leak, codes
preserved); A-10's `mytool` must carry the trap; M09's `stackctl` wraps `up` and
`destroy` in `flock envs/<env>.lock` and renders its compose file into a `mktemp`
directory that the trap removes.

---

## Self-check answers

1. No — the status is consumed by `if`; strict mode only aborts on an *unhandled* failure (observed: `n`).
2. `(( x++ ))` yields the old value `0`, which arithmetic treats as false (status 1); `(( ++x ))` yields `1` (observed: `status=1` vs `x=1`).
3. With capture (`rc=$?; …; exit "$rc"`) the caller sees `3`; without it, the failing cleanup trips `set -e` inside the trap and the status becomes `1` (observed: `3` vs `1`).
4. It does not wait: it exits immediately with status 1 and does not run `cmd` (observed: `busy … (status 1)`).
5. Two runs (or two users) would share and overwrite one file; `mktemp` guarantees a fresh, private name every time, and the trap removes it — no collisions, no leaks.
6. Leak 1, the argument list: the expanded password sits in `docker`'s `argv` for the length of the call, visible to `ps` (observed with `--password=hunter2`); pipe it in instead — `bao kv get … | docker login … --password-stdin` (S07.6).

**Read the real thing.** (a) S07.2 — cleanup by `trap … EXIT`, not by a line at the end. The script runs without `-e`, so a failing `ssh` does *not* abort it and the last line still runs; what leaves `$tmp` and its four files behind is anything that cuts the script short of that line — Ctrl-C, a `kill`, a closed terminal, or a `set -u` abort on an unset name (observed on a copy without the trap: an exit before the cleanup line left the directory; with the trap, it was gone). It belongs on the same line as `mktemp` because the window between *creating* the directory and *arming* its cleanup is the one place an abort can still leak it — the shorter that window, the better; one statement makes it zero. (b) The *missing* case. With `[ -f "$s" ] && …`, a report that was never written makes the test false, the chain is not taken, and the loop moves on — `PHASE1-DONE`, status 0 (observed on the old line: identical output with and without the `[ -f ]`; the only difference was `jq`'s `Could not open file` noise). A scanner killed by a timeout (its `|| true` swallowed that) therefore produced a silent pass. The function fails that case explicitly (`MISSING REPORT: … status 1`, observed) and also the half-written one (`UNREADABLE REPORT`), which the old line missed for the same reason — `jq` exits 2 and `&&` is not taken. This defect was found by this course's audit and fixed in Course 2 on 2026-11-02; the lesson is the same as S07.1's: a condition that is *skipped* is not a condition that *passed*.


> **TRAINER ONLY — end of module.** Debrief: "Which single line would you add first to a colleague's cron script that writes to `/tmp/report.txt`?" (expected: `mktemp` + the code-preserving trap; second answer: `flock` if two instances may overlap). **Prepare M08:** `shellcheck` must be installed for the full M08 experience (the gate is a real check); `logsleuth/tests/run.sh` must run green (`# 17 passed, 0 failed`, observed). **Session close:** record A-08; collect `work/worker.sh` and `work/REFLECTION.md`; remind learners to `rm -rf /tmp/lab7.*`.
> *Batch 6 addition (2026-10-25), reframed in Batch 8 (2026-11-02) after both defects were fixed upstream:* the page ends with a 5-min reading of `program/scripts/replica-check.sh` and `program/ci/validate_unauth.sh` **as fixed**. Tell the story: both scripts shipped with real defects (no `trap` after `mktemp -d`; a gate that skipped never-written reports) that *this course's* audit found; the fixes are the ones the learners now read. Answer (a) is S07.2's trap-on-the-same-line habit and the zero-width window argument; the subtle part is *when* the old version leaked — not on a failed `ssh` (no `-e`, so the last line still ran) but on an interruption or a `-u` abort. A learner who says "when ssh fails" has not noticed the missing `-e`; send them to S07.1. Answer (b) is the *missing* case: the old one-liner's `[ -f ]` made a never-written report indistinguishable from a clean one (observed on the old line: `PHASE1-DONE`, status 0 with or without the test). A learner who answers "the unreadable case" is half right — say that the old line missed it too, and for the same reason (`&&` not taken). Live demo that lands: copy the function into a shell, `sarif_gate nope.sarif` → `MISSING REPORT`, status 1.