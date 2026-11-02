# Lab 7 exercise — robustness: traps and signals

You make a script that never leaks a temp directory and never corrupts its own
exit code — the guarantees logsleuth lives by. You edit `worker.sh`.

## The contract
`worker.sh <marker> [exitcode]`
- creates a temp dir and writes its path to `<marker>` (so the grader can watch it),
- removes the temp dir on **any** exit or signal,
- exits with `<exitcode>` (default 0), preserving it **through** the cleanup trap.

## Do it
1. `bash grade.sh` — seeds `work/` and grades it. The starter leaks its temp dir
   and ignores the exit code, so those checks FAIL.
2. Edit `work/worker.sh`:
   - add `trap 'rc=$?; rm -rf "$d"; exit "$rc"' EXIT INT TERM` — capture `$?`
     first, clean up, then re-exit with the real code (a bare cleanup that fails
     would clobber the code to 1 under `set -e`).
   - change the final line to `exit "${2:-0}"`.
3. Re-run until `---- lab7: N passed, 0 failed ----`.

## Your deliverable
`work/worker.sh` fully green — the capture-and-re-exit trap idiom `logsleuth/bin/logsleuth`
uses (on EXIT; the worker adds INT TERM so signals funnel into the same cleanup).
