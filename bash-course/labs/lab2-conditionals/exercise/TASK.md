# Lab 2 exercise — conditionals and `case`

You implement logsleuth's two gatekeepers in `router.sh`.

## What you build
- `validate_log` — return success when a log file is readable, else print
  `cannot read log file: <path>` and fail. Uses `[[ -r ... ]]`.
- `route` — map the first argument to `valid` / `brute` / `unknown` with a
  `case` statement (how logsleuth turns `summary`, `top`, `bruteforce`, … into
  the right handler).

## Do it
1. `bash grade.sh` — seeds `work/` and grades it; checks FAIL until you fill the TODOs.
2. Edit `work/router.sh`:
   - `validate_log`: `if [[ -r "$f" ]]; then return 0; else printf '...' >&2; return 1; fi`.
   - `route`: a `case "$1"` with `summary|top|errors`, a `brute*` prefix, and a `*` catch-all.
3. Re-run until `---- lab2: N passed, 0 failed ----`.

## Your deliverable
`work/router.sh` fully green. `solution/router.sh` is the reference.
