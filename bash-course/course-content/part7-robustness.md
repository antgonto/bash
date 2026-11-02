# Part 7 — Robustness: errors, traps, and signals

> Graded by `labs/lab7-robustness/exercise/grade.sh`. Making a script safe to run
> in production. In this part you build a worker that never leaks a temp directory
> and never corrupts its own exit code — logsleuth's core guarantee.

**What you'll build.** In `labs/lab7-robustness/exercise/` you complete `worker.sh`
so it cleans up on any exit or signal and preserves its exit code. First, the moves.

---

## Step 1 — The sharp edges of `set -e`

Two facts explain most "why did my strict script die?" moments:

```bash
bash -c 'set -e; if grep -q zzz <<<"abc"; then echo y; else echo n; fi'  # consumed by if -> safe
bash -c 'x=0; if (( x++ )); then echo t; else echo f; fi'                 # (( x++ )) returns FAILURE when x was 0
```
```text
n
f
```

`set -e` does **not** fire for a command whose status is consumed by `if`, `&&`,
or `||`; and `(( x++ ))` returns failure when `x` was 0 — use `(( ++x ))`.

---

## Step 2 — `trap`: clean up on any exit

```bash
bash -c '
  set -euo pipefail
  d="$(mktemp -d)"
  trap "rm -rf \"$d\"; echo cleaned >&2" EXIT
  echo "working in a temp dir"
' 2>&1
```
```text
working in a temp dir
cleaned
```

`trap '…' EXIT` runs on success, failure, or `set -e`. Create temps with `mktemp`
so two runs never collide, and let the trap remove them — on `EXIT INT TERM` so
Ctrl-C and `kill` are covered too.

---

## Step 3 — The EXIT-trap status gotcha (what logsleuth gets right)

Under `set -e`, a **failing command inside the EXIT trap** clobbers the exit code
to 1 — even if a cleanup function would later `return 0` (it never gets there). The
reliable fix is to capture `$?`, clean, and re-exit with it:

```bash
bash -c '
  set -e
  cleanup(){ rm -rf /nonexistent-xyz 2>/dev/null || true; }
  trap "rc=\$?; cleanup; exit \$rc" EXIT
  exit 3
'
echo "exit code: $?"
```
```text
exit code: 3
```

Capturing and re-exiting preserves the real code — including `logsleuth
bruteforce`'s meaningful exit 3.

---

## Your exercise

Open `labs/lab7-robustness/exercise/` and read `TASK.md`. You complete `worker.sh`
to the contract `worker.sh <marker> [exitcode]`:
- create a temp dir, publish its path to `<marker>`,
- clean it up on **any** exit or signal,
- exit with `<exitcode>` (default 0), preserved through the trap.

```bash
cd labs/lab7-robustness/exercise
bash grade.sh                 # seeds work/ and grades it
# ...add the trap and fix the exit line in work/worker.sh...
bash grade.sh                 # until: ---- lab7: N passed, 0 failed ----
```

Add the trap as: `trap 'rc=$?; rm -rf "$d"; exit "$rc"' EXIT INT TERM` (keep the
`# shellcheck disable=SC2154` line above it).

---

## What you can do at the end of Part 7

Write scripts that fail loudly, clean up on any exit or signal without corrupting
their status, and guard shared resources. You just wrote the capture-and-re-exit
trap idiom `logsleuth/bin/logsleuth` uses (on EXIT; your worker adds INT TERM) —
the difference between a demo and a tool you can schedule and trust.
