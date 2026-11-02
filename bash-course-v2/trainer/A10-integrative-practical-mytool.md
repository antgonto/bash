# A-10 — Integrative practical: assemble `mytool`
**FULL TRAINER EDITION · curriculum v2.0.0-draft · assessment time 1.00 h**
(build 45 min · decisions note 15 min)

> **TRAINER ONLY — about this edition.** Student text verbatim; trainer blocks inserted. This page holds the complete A-10 solution, the R-10 level descriptors, calibration samples, the scoring procedure, and the **A-10R** reassessment kit. None of it may reach a student-visible Moodle area.
>
> **Prep (≈20 min, once per cohort).** 1) `cd labs/capstone/exercise && rm -rf work && bash grade.sh` → **observed** `---- capstone: 2 passed, 10 failed ----`; `GRADE_TARGET="$PWD/solution" bash grade.sh` → **observed** `---- capstone: 12 passed, 0 failed ----`. 2) `bash labs/capstone/lab.sh` → **observed** `---- capstone: 22 passed, 0 failed ----` — this is the reference tool (`logsleuth`) proven end to end: install, every subcommand, exit codes 0/1/2/3, pipeline composition, green suite, shellcheck gate, no temp leak, config read as data. Per the packaging plan it is **trainer-side** for the A-10 scope (it is the answer key for "what the finished standard looks like"); the student page does not point to it. 3) Rehearse A-10R once: `bash trainer/a10r/grade-A10R.sh trainer/a10r/solution/linetool` → **observed** `---- A-10R: 12 passed, 0 failed ----`.
>
> **Trainer effort:** prep 20 min; per learner ≈ 12 min (grader 2 min, note 10 min). **Integrity:** AI is allowed for documentation lookup and must be disclosed in the note; the note (R-10.7, weight 6) is the evidence of independent understanding — a learner cannot pass on the grader alone (14/20 = 70%). Do not distribute `solution/`; if a learner's `mytool` is byte-identical to the reference, treat it as a non-submission and issue A-10R.
>
> **Scheduling.** Issue after A-09. Self-paced learners time themselves; record their reported duration in V-05 (the 60-minute figure is a design target, not measured).


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


> **TRAINER ONLY — running the assessment.** Collect three files: `work/mytool`, `work/DECISIONS.md`, `work/GRADER.txt`. Re-run the grader yourself on their copy — never trust the pasted output alone: `GRADE_TARGET=/path/to/their/work bash labs/capstone/exercise/grade.sh`. If shellcheck is missing on *your* machine the last check reports a skipped PASS; certify R-10.6 only where shellcheck runs. If the learner ran out of time: score what exists at 60 minutes for the check-backed criteria and let them finish the note afterwards (the note is reflective, not timed); if the result is Not yet, remediate and issue **A-10R**, never a second attempt at the same `mytool` with the solution now in hand.

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


> **TRAINER ONLY — complete solution (reference `labs/capstone/exercise/solution/mytool`, observed 12/12):**
> ```bash
> #!/usr/bin/env bash
> # Capstone solution — mytool: a tiny line-analyzer that scores every row of the
> # rubric logsleuth meets (strict mode, usage, getopts, case dispatch, file-or-
> # stdin, distinct exit codes, a cleanup trap).
> set -euo pipefail
> PROG="mytool"
>
> tmp="$(mktemp "${TMPDIR:-/tmp}/$PROG.XXXXXX")"
> # shellcheck disable=SC2154  # rc is assigned inside the trap string, then used
> trap 'rc=$?; rm -f "$tmp"; exit "$rc"' EXIT INT TERM
>
> usage() {
>   cat <<EOF
> usage: $PROG [-n N] <count|top> [FILE]
>   count        number of lines (FILE or stdin)
>   top          the most frequent line(s)
>   -n N         for 'top', show the top N (default 1)
> EOF
> }
>
> n=1
> while getopts ":n:h" opt; do
>   case "$opt" in
>     n)  n="$OPTARG" ;;
>     h)  usage; exit 0 ;;
>     :)  printf '%s: -%s needs an argument\n' "$PROG" "$OPTARG" >&2; exit 2 ;;
>     \?) printf '%s: unknown option -%s\n' "$PROG" "$OPTARG" >&2; exit 2 ;;
>   esac
> done
> shift $((OPTIND - 1))
>
> [[ $# -ge 1 ]] || { usage >&2; exit 2; }
> cmd="$1"; shift
>
> # read FILE-or-stdin into the temp file
> if [[ $# -ge 1 ]]; then
>   [[ -r "$1" ]] || { printf '%s: cannot read file: %s\n' "$PROG" "$1" >&2; exit 1; }
>   cat -- "$1" > "$tmp"
> else
>   cat > "$tmp"
> fi
>
> case "$cmd" in
>   count) wc -l < "$tmp" | tr -d ' ' ;;
>   top)   sort "$tmp" | uniq -c | sort -rn | head -n "$n" | sed 's/^ *[0-9]* //' ;;
>   *)     printf '%s: unknown command: %s\n' "$PROG" "$cmd" >&2; exit 2 ;;
> esac
> ```
> **Observed behavior of the reference** (use it to answer "is this right?"): `-h` → four usage lines on stdout, exit 0; no arguments → usage on **stderr**, exit 2; `-n` alone → `mytool: -n needs an argument`, exit 2; `-x` → `unknown option -x`, exit 2; `count /nope` → `cannot read file: /nope`, exit 1; `frob FILE` → `unknown command: frob`, exit 2; `-n 2 top` on the grader's data → `apple` then `banana`; `printf 'a\nb\nb\n' | mytool top` → `b`. After any number of runs `ls /tmp/mytool.*` is unchanged (the starter, by contrast, leaks one file per run — observed).
>
> **Deviations and how they score.** `trap 'rm -f "$tmp"' EXIT` — passes check 11, **R-10.5 Met** (not code-preserving; S07.3 was the lesson). `exit 1` for an unknown command — fails check 7, **R-10.2 Not met → fails the assessment** (critical). Usage to stderr for `-h` — fails check 9. `cat "$1"` without `--` — passes everything, **R-10.1 Met** (deviation the course warned about in S06.4). No `local`/function structure — not assessed here (the tool is a single script by design). `#!/bin/bash` — passes (the grader does not check the shebang) but note it in feedback. An implementation that skips the temp file and reads `"${1:-/dev/stdin}"` directly can pass all 12 checks if a trap line is still present; it is **not** a deviation to penalize — score it on its merits and expect D3 to reason about its *own* design.

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


> **TRAINER ONLY.** Watch for two things during the build: learners who edit `grade.sh` (never acceptable — compare with the course copy), and learners who paste the whole solution from an AI tool — allowed only for *documentation lookup*; the note is where you find out. The starter's `# TODO` comments are deliberately explicit (they quote the shape of each line); A-10 tests *assembly and understanding*, A-10R tests the same with the scaffolding removed. The observed leak demonstration (`ls /tmp/mytool.* | wc -l` growing by one per run until the trap is in) is worth pointing out to the whole cohort — it is the only moment in the course where a learner *sees* a temp leak accumulate.

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


> **TRAINER ONLY — level descriptors (Not met / Met / Strong).**
> - **R-10.1 Functional (w 5).** *Not met:* any of checks 1–4 fails except as below. *Met:* exactly one of the four fails **or** all pass but input handling deviates from the taught form (`cat` without `--`, no readability check before reading). *Strong:* all four pass with `cat -- "$1"` guarded by a readability test.
> - **R-10.2 Exit codes (w 3, critical).** *Not met:* any of checks 5–8 fails (good run ≠ 0, unknown command ≠ 2, unreadable file ≠ 1). *Met:* all pass but a usage-class error (missing `-n` argument, unknown option) exits with a code other than 2, or error text goes to stdout. *Strong:* all pass; every usage-class error exits 2 with a message on stderr; runtime failure exits 1.
> - **R-10.3 Usage (w 1).** *Not met:* check 9 fails. *Met:* passes but usage lacks the subcommands or the `-n` option. *Strong:* passes; usage names both subcommands, `-n`, and the FILE-or-stdin rule.
> - **R-10.4 Strict mode (w 1).** *Not met:* check 10 fails. *Met:* `set -euo pipefail` present but not within the first lines (after code that could fail unguarded). *Strong:* header at the top, as in M00.
> - **R-10.5 Trap (w 2, critical).** *Not met:* check 11 fails (no trap line, or more than one — the grader counts exactly one line beginning `trap `). *Met:* a trap removes the temp file but does not capture and re-exit `$?`. *Strong:* `trap 'rc=$?; rm -f "$tmp"; exit "$rc"' EXIT INT TERM` (or equivalent capture-and-re-exit) — observed to preserve codes 0/1/2.
> - **R-10.6 shellcheck (w 2, critical).** *Not met:* any finding (info counts). *Met:* clean only with a `# shellcheck disable=` other than the course's `SC2154` line. *Strong:* clean with at most the `SC2154` disable the starter provides.
> - **R-10.7 Decisions note (w 6).** Scored on the three answers together: *Not met:* missing, under ~60 words, or answers that restate the question / name no mechanism / contradict the submitted code. *Met:* each answer names the mechanism (see model answers) in the learner's own words. *Strong:* at least two answers go beyond — an observation from the modules, a concrete failure that the choice prevents, or a correct link to `logsleuth`/M09 — and the AI-use disclosure is present (or an explicit "none").
>
> **Model answers for R-10.7.**
> - **D1 — Met:** `$?` holds the exit status only until the next command runs, so the trap must save it before `rm -f`; under `set -e` a failing cleanup would otherwise turn the exit into `1` and the tool's `2` (usage) or `1`-vs-`0` distinction would be lost. **Strong:** quotes S07.3 (`status=1` vs `status=3`) or names `logsleuth bruteforce`'s `3` as the code this idiom protects.
> - **D2 — Met:** `-h` output *is* the requested result, so it belongs on stdout where `mytool -h | less` or a caller can read it; an error message must not pollute captured output, so it goes to stderr; exit 2 tells a caller (a wrapper, cron, `||`) that the *command line* was wrong rather than that a file was unreadable (1). **Strong:** gives a concrete consumer for each (`out=$(mytool …)` for stderr; `mytool … || alert` or a CI step for the code), or cites the grader's `-h 2>/dev/null | grep -q usage` as the reason stdout matters.
> - **D3 — Met:** the temp file lets the tool treat stdin and a file identically and read the data once (stdin cannot be rewound) so `count` and `top` share one path; in return the trap must remove the file on every exit, including signals, or the tool leaks a file per run (observed with the starter). **Strong:** names `mktemp`'s uniqueness (no collisions between concurrent runs) or the `TMPDIR` convention, or notes the alternative (`/dev/stdin`) and its trade-off.
>
> **Scoring procedure (≈12 min/learner).** 1) Re-run the grader on their copy. 2) Read `mytool` for the Strong/Met distinctions above (five minutes: trap line, `--`, where usage goes, exit codes in the error branches, shellcheck disables). 3) Read the note against the model answers. 4) Compute Σ(weight × level/2) / 20. 5) **Pass** only if ≥ 80% **and** R-10.2, R-10.5, R-10.6 are each ≥ Met. 6) Record `A-10 PASS` or `A-10 NOT YET` with the per-criterion levels (that record is the remediation plan).
>
> **Worked examples (observed arithmetic).** All Strong → 20/20. Everything Strong but no note → 14/20 = **70%, fail**. All Strong, note Met → 17/20 = 85%, pass. R-10.1 Met (`cat` without `--`), R-10.5 Met (bare `rm` trap), note Strong → 2.5 + 3 + 1 + 1 + 1 + 2 + 6 = 16.5/20 = 82.5%, pass — with two deviations to feed back. `exit 1` for an unknown command, everything else Strong → 17/20 = 85% **but R-10.2 Not met → fail** (critical gate).
>
> **Calibration samples for D1.** *Strong:* "The trap saves `$?` into `rc` first because every command, including `rm -f`, replaces `$?`. If the cleanup failed under `set -e` the script would exit 1 — in M07 I saw `with -e: status=1` versus `status=3` once the code was captured — so my `exit 2` for a bad option would come out as 1 and a wrapper could not tell a typo from a missing file." *Met:* "`rc=$?` saves the real exit code before cleanup so that `exit "$rc"` can return it; otherwise a failing `rm` would change it." *Not met:* "You have to save the return code so the script returns the right code." (restates; no mechanism, no failure named).
>
> **Model feedback (Not yet):** "`unknown command exits exactly 2` FAILED: your `*)` branch exits 1 — the course reserves 1 for runtime failures; usage mistakes are 2 (S06.5). This is a critical criterion, so A-10 is Not yet regardless of the rest. Remediation: S06.5 and S02.4, then A-10R." **Remediation map:** R-10.1 → S06.4, S05.3; R-10.2 → S06.5; R-10.3 → S06.5 (stdout vs stderr); R-10.4 → S00.7; R-10.5 → S07.3–S07.4; R-10.6 → S00.9, S08.3; R-10.7 → re-read the relevant step and rewrite in own words.
>
> **A-10R — equivalent reassessment (kit in `trainer/a10r/`, trainer-only).** Same 12-check shape and the same R-10 weights/levels/critical gates; different names and codes so the first attempt cannot be pasted in: `linetool lines [FILE]`, `linetool [-k N] freq [FILE]`, `linetool -h`; exit map **0 / 3 (unreadable file) / 4 (usage or unknown command)**. The starter `trainer/a10r/starter/linetool` states only the contract — **no line-by-line TODO hints** — so A-10R also evidences independent assembly. Grade with `bash trainer/a10r/grade-A10R.sh /path/to/their/linetool` → require `---- A-10R: 12 passed, 0 failed ----` (**observed:** reference `solution/linetool` 12/12; the contract-only starter 2/12; the original A-10 grader scores the A-10R reference only 5/12, confirming the variant is distinct). Use the same three decision prompts with the names and codes substituted. `TASK-A10R.md` in the kit is the hand-out text.
>
> **Evidence handling.** Keep `mytool`, `DECISIONS.md`, your re-run grader output, and the per-criterion levels; text only. Reset for the next session: learners `rm -rf work` and `rm -f /tmp/mytool.*`.

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


> **TRAINER ONLY.** This transfer task is where the course's "hero" claim is actually tested, and it is ungraded by design (no rubric can anticipate the tool). If you run a cohort, ask each learner to demo their own tool for five minutes against the checklist; the two items most often missing are the config-as-data rule and the test suite. Learners who finish early while others complete A-10 should start here rather than on M09, which needs a Docker daemon.


> **TRAINER ONLY — end of the integrative practical.** Record the A-10 result and levels. **Route:** PASS → M09 (confirm Docker is installed and running — S00.1–S00.3 — before the session; the fallback shell is not enough for M09). NOT YET → remediation map above, then A-10R; a second NOT YET means the learner should repeat the module whose criterion failed before trying again. **Certificate wording reminder:** without a human or configured reviewer inspecting A-10 evidence, completion is *self-assessed* (blueprint §6, evidence boundary).