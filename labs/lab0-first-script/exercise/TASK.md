# Lab 0 exercise — your first script

You build `greet`, the small usable script from Part 0 of the lessons.

## What you build
`greet [NAME]` — prints `Hello, <name>!` (default `world`), under the strict-mode
header, shellcheck-clean.

## Do it
1. `bash grade.sh` — seeds `work/` and grades it; every check FAILs at first.
2. Edit `work/greet`, following Part 0's steps:
   - add the header `set -euo pipefail` and `IFS=$'\n\t'`,
   - `name="${1:-world}"`,
   - `printf 'Hello, %s!\n' "$name"`.
3. Re-run until `---- lab0: N passed, 0 failed ----`.

## Your deliverable
`work/greet` fully green — a real command you can `cp` onto your PATH.
