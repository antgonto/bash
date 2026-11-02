# M07 — Robustness: `set -e` edges, traps, temp files, locks
**Student Edition · curriculum v2.0.0-draft · self-paced, no fixed duration**

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

---

## Knowledge checks (predict, then run)

1. Under `set -e`, does `if grep -q x file; then …; fi` abort when `grep` finds nothing?
2. Why does `(( x++ ))` abort a strict-mode script when `x` is 0, while `(( ++x ))` does not?
3. A script does `exit 3` and its EXIT trap runs `rm -rf "$d"`, which fails. Under `set -e`, what status does the caller see — with and without `rc=$?` capture?
4. What does `flock -n lockfile cmd` do when another process holds the lock?
5. Why create temp files with `mktemp` rather than a fixed name like `/tmp/work`?
6. Course 2 runs `docker login harbor… -u admin -p "$(bao kv get -field=password …)"`. Which of S07.6's four leaks is that, and what is the fix?

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
