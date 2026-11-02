#!/usr/bin/env bash
# Lab 7 exercise — a temp dir that is always cleaned up, and an exit code that
# survives the cleanup trap.  Contract:  worker.sh <marker> [exitcode]
#   - create a temp dir, write its path to <marker> so the grader can watch it
#   - clean the temp dir up on ANY exit or signal
#   - exit with <exitcode> (default 0), preserving it through the trap
# Complete each TODO, then run:  bash ../grade.sh
set -euo pipefail

d="$(mktemp -d "${TMPDIR:-/tmp}/lab7.XXXXXX")"

# TODO: install a trap that removes "$d" on EXIT INT TERM AND preserves the code.
# shellcheck disable=SC2154  # (keep this line; rc is assigned inside the trap)
#   trap 'rc=$?; rm -rf "$d"; exit "$rc"' EXIT INT TERM

printf '%s\n' "$d" > "$1"     # publish our temp dir

# TODO: exit with the code passed as $2 (default 0) instead of this hard-coded 0.
exit 0
