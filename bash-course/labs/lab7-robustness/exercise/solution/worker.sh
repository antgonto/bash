#!/usr/bin/env bash
# Lab 7 solution — signal-safe temp cleanup with a code-preserving trap.
# Contract:  worker.sh <marker> [exitcode]
set -euo pipefail

d="$(mktemp -d "${TMPDIR:-/tmp}/lab7.XXXXXX")"
# shellcheck disable=SC2154  # rc is assigned inside the trap string, then used
trap 'rc=$?; rm -rf "$d"; exit "$rc"' EXIT INT TERM   # INT/TERM funnel into EXIT

printf '%s\n' "$d" > "$1"     # publish our temp dir so the grader can watch it

exit "${2:-0}"
