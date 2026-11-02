# A-10 — Integrative practical: assemble `mytool`
**Student Edition · curriculum v2.0.0-draft · assessment time 1.00 h**
(build 45 min · decisions note 15 min)

**What this is.** The summative check for the core course (LO-01…LO-09). No new
concepts: you assemble everything M00–M08 taught into one small command-line
tool and hold it to the same bar `logsleuth` meets. Two things are assessed — the
grader's 12 checks on your `mytool`, and a short **decisions note** in your own
words — scored with the rubric below.

**Prerequisite check.** A-01…A-09 passed. If any grader in `labs/lab*/exercise` is
not green, finish it first: A-10 reuses every move.

---

## Assessment context

| Field | Value |
|---|---|
| Location | `labs/capstone/exercise/` (read `TASK.md`) |
| Time | 60 minutes, self-timed: ≈45 min to build, ≈15 min for the note |
| Allowed resources | The module pages, any documentation, AI assistance **for documentation lookup only** (say so in the note); **not** `solution/`, and not another learner's `mytool` |
| Deliverables | `work/mytool` and `work/DECISIONS.md` (≈150 words, three answers) |
| Acceptance | `bash grade.sh` ends `---- capstone: 12 passed, 0 failed ----` **and** the weighted rubric score is ≥ 80% with no *critical* criterion at Not met |
| Reassessment | A-10R: the same rubric on an equivalent tool with different subcommand names and a different exit-code map, issued by your trainer |
| Validation status | The reference solution scores 12/12 and the starter 2/12 in the authoring environment (observed 2026-10-19); nothing here needs Docker |

---

## The task

`mytool` is a tiny line-analyzer:

- `mytool count [FILE]` — the number of lines (from FILE, or from stdin when FILE is omitted)
- `mytool [-n N] top [FILE]` — the most frequent line(s); `-n N` shows the top N (default 1)
- `mytool -h` — usage, on **stdout**, exit 0

It must be built the way every tool in this course is built:

- strict mode (`set -euo pipefail`) and a **temp-file cleanup trap** that preserves the exit code (M07)
- `getopts` for `-n`/`-h` with your own error handling, and a `case` dispatcher for the subcommand (M06, M02)
- input from a **FILE or stdin** (M06)
- **distinct exit codes**: `0` ok · `1` unreadable file · `2` usage error or unknown command (M06)
- **shellcheck-clean** (M00, M08)

---

## Procedure

1. `cd labs/capstone/exercise && bash grade.sh` — seeds `work/mytool` from the starter and runs the rubric. **Observed on the starter:** `---- capstone: 2 passed, 10 failed ----`. Also run `ls /tmp/mytool.* 2>/dev/null | wc -l` now and after a few grader runs: the starter creates its temp file but has **no trap**, so the count grows by one per run (observed) — you will watch it stop growing once your trap is in.
2. Open `work/mytool`. The starter is the skeleton of the finished tool with `# TODO` markers in the order you should fill them: the trap, `usage`, the `getopts` loop, the subcommand check, FILE-or-stdin into the temp file, the `case` dispatch. Each marker tells you *what* the line must do; the modules showed you *how* (S07.3–S07.4, S06.2, S06.4–S06.5, S02.3, S05.3).
3. Re-run `bash grade.sh` after each change and read the first FAIL. Keep going until **`---- capstone: 12 passed, 0 failed ----`** (observed with the reference). Run `shellcheck work/mytool` yourself before the final grader run.
4. Write `work/DECISIONS.md` — about 150 words in total, your own words, three short answers:
   - **D1.** Your trap begins with `rc=$?`. Why there, and which of *your* exit codes would be lost without it?
   - **D2.** `mytool -h` prints usage to stdout and exits 0; a usage *mistake* prints to stderr and exits 2, not 1. Who depends on each of those two choices?
   - **D3.** `mytool` copies its input (file or stdin) into a `mktemp` file before running `wc`/`sort` on it. What does the temp file buy you, and what does the trap then owe in return?
5. Hand in `work/mytool`, `work/DECISIONS.md`, and your final grader output (`bash grade.sh > work/GRADER.txt 2>&1` from the exercise folder).

**Hints (graduated).** H1: read only the *first* FAIL; the checks are ordered so that fixing it usually unlocks the next. H2: `top`'s pipeline is M05's counting idiom plus `sed 's/^ *[0-9]* //'` to drop the counts. H3: if `-h prints usage and exits 0` fails while `-h` works in your terminal, the grader runs with `2>/dev/null` — your usage must go to **stdout** for `-h`.

**Reset.** `rm -rf work && bash grade.sh`; remove leaked temp files with `rm -f /tmp/mytool.*`.

---

## Rubric R-10 (learner-visible)

Each criterion is judged at one of three levels — **Not met** (0) · **Met** (1) ·
**Strong** (2) — and scored as `weight × level / 2`. **Pass** = total ≥ 80% of the
maximum (20) **and** no *critical* criterion at Not met. *Strong* means "built to
the standard the modules taught"; *Met* means "works, but with a deviation the
modules warned you about"; *Not met* means a check fails. The detailed level
descriptors are in the Trainer Edition.

| ID | Criterion | Evidence | Weight | Critical |
|---|---|---|---|---|
| R-10.1 | Functional: `count` (file and stdin), `top`, `top -n N` | grader checks 1–4 | 5 | — |
| R-10.2 | Exit codes are a correct API: `0` ok, `1` unreadable file, `2` usage / unknown command | grader checks 5–8 | 3 | **yes** |
| R-10.3 | `-h` prints usage to stdout and exits 0 | grader check 9 | 1 | — |
| R-10.4 | Strict mode header | grader check 10 | 1 | — |
| R-10.5 | Cleanup trap present and code-preserving | grader check 11 + review of the trap line | 2 | **yes** |
| R-10.6 | shellcheck-clean | grader check 12 | 2 | **yes** |
| R-10.7 | Decisions note: three answers that name the mechanism in your own words | `DECISIONS.md` | 6 | — |

A green grader with no decisions note scores 14/20 = 70% — **not a pass**. The note
is where you show the understanding the grader cannot see.

---

## In the SecMLOps Program
`mytool` is the smallest complete tool in the program's style: strict mode, `getopts` + `case`, file-or-stdin, distinct exit codes, a code-preserving trap, shellcheck-clean. Hold Course 2's `ci/*.sh` scripts to the same checklist when you meet them — most pass; where one does not (a key file with no trap, an `export` that hides an exit status), you now have the vocabulary to say exactly what is missing and why it matters.

---

## After A-10 — do it again on a tool of your own (optional, ungraded)

Write a bash tool you actually want — a backup rotator, a deploy helper, a report
generator — to the same checklist:

- `#!/usr/bin/env bash` + `set -euo pipefail` + a clear `usage()`
- `getopts` for options, a `case` dispatcher for subcommands
- logic in functions in a sourced `lib/`, not one long script
- reads a FILE argument **or** stdin; quotes every expansion
- distinct exit codes (`0` ok / `1` runtime / `2` usage / tool-specific above)
- a `trap` that cleans up temp files on any exit, with the code preserved
- a config file parsed as **data** (never `source`d)
- a test suite (`assert.sh`-style) that is green
- **zero** shellcheck findings

That is the "hero" the course set out to reach: someone who ships bash tools
other people can trust. M09 applies exactly this skeleton to infrastructure.
