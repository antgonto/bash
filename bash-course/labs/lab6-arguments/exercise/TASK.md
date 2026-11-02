# Lab 6 exercise — arguments, options, and UX

You give logsleuth a real command line in `cli.sh`.

## What you build
- `parse_opts` — a `getopts` loop handling `-n N` (default 10), a `-v` flag,
  a missing argument, and an unknown option; prints `n=.. v=.. rest=..`.
- `read_input` — read a named FILE if given, else stdin (so the tool composes in pipelines).

## Do it
1. `bash grade.sh` — seeds `work/` and grades it.
2. Edit `work/cli.sh`:
   - `parse_opts`: `while getopts ":n:v" opt; do case "$opt" in …; esac; done; shift $((OPTIND-1))`.
     The leading `:` in `":n:v"` turns on your `:` (missing arg) and `\?` (unknown) handling.
   - `read_input`: `if [[ $# -ge 1 ]]; then cat -- "$1"; else cat; fi`.
3. Re-run until `---- lab6: N passed, 0 failed ----`.

## Your deliverable
`work/cli.sh` fully green — the parsing and input handling behind logsleuth's CLI.
