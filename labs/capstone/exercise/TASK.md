# Capstone exercise — assemble your own tool

No new concepts. You assemble everything the course taught into one small, real
command-line tool, `mytool`, and make it pass the rubric logsleuth meets.

## What `mytool` does
A tiny line-analyzer:
- `mytool count [FILE]` — number of lines (FILE or stdin)
- `mytool [-n N] top [FILE]` — the most frequent line(s)
- `mytool -h` — usage

## The rubric (what the grader checks)
- strict mode (`set -euo pipefail`) and a temp-file cleanup **trap**
- `getopts` for `-n`/`-h`; a `case` dispatcher for the subcommand
- reads a **FILE or stdin**
- **distinct exit codes**: `0` ok, `1` unreadable file, `2` usage / unknown command
- **shellcheck-clean**

## Do it
1. `bash grade.sh` — seeds `work/` and runs the rubric; the starter FAILs most rows.
2. Fill every `# TODO` in `work/mytool` (each quotes the exact line you need).
3. Re-run until `---- capstone: N passed, 0 failed ----`.

## Your deliverable
`work/mytool` passing the whole rubric — then do it again on a tool of your own
(a backup rotator, a deploy helper), to the same bar. That is the "hero" the
course set out to reach: someone who ships bash tools other people can trust.
