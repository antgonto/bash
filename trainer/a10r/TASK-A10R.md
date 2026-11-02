# A-10R — equivalent reassessment of A-10 (TRAINER ONLY until issued)

Issue this only to a learner who did not pass A-10. Same rubric shape (12 checks,
R-10 criteria and weights, three critical gates); different names and codes so the
first attempt's work cannot be pasted in.

## Contract the learner receives
`linetool` — a tiny line-analyzer:
- `linetool lines [FILE]` — number of lines (FILE or stdin)
- `linetool [-k N] freq [FILE]` — the N most frequent line(s), default 1
- `linetool -h` — usage to stdout, exit 0
- exit codes: **0** ok · **3** unreadable file · **4** usage error / unknown command
- strict mode, a code-preserving cleanup trap, `getopts`, `case` dispatch,
  FILE-or-stdin, shellcheck-clean

Give them `starter/linetool` (contract only, no line-by-line hints) and 60 minutes;
collect `linetool` and a 150-word decisions note (same three questions as A-10).

## Grading
`bash grade-A10R.sh /path/to/their/linetool` → require `---- A-10R: 12 passed, 0 failed ----`
for the check-backed criteria, then score the note with the A-10 descriptors.
The reference in `solution/linetool` scores 12/12 (observed).
