#!/usr/bin/env bash
# run.sh — the logsleuth test suite. Generates fixtures, sources the library,
# runs every test_*.sh, and exits non-zero if any assertion failed.
#   ./tests/run.sh            # uses seed/make_logs.sh for fixtures
#   LOGSLEUTH_FX=dir ./tests/run.sh   # reuse an existing fixtures dir
set -uo pipefail
TESTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TESTDIR/assert.sh"

if [[ -n "${LOGSLEUTH_FX:-}" ]]; then FX="$LOGSLEUTH_FX"
else FX="$(mktemp -d)"; trap 'rm -rf "$FX"' EXIT
     bash "$TESTDIR/../../seed/make_logs.sh" "$FX" >/dev/null; fi

# the code under test
# shellcheck source=../lib/util.sh
source "$TESTDIR/../lib/util.sh"
# shellcheck source=../lib/parse.sh
source "$TESTDIR/../lib/parse.sh"
# shellcheck source=../lib/report.sh
source "$TESTDIR/../lib/report.sh"

for f in "$TESTDIR"/test_*.sh; do
  # shellcheck source=/dev/null
  source "$f"
done
t_summary
