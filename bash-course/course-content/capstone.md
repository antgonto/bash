# Capstone — the finished tool, and your own

> Proven by `labs/capstone/lab.sh` (the reference tool) and built by you in
> `labs/capstone/exercise/`. No new concepts — the whole course standing up at
> once, and the template for the next tool you write.

By now you have built logsleuth's pieces: name helpers, input validation and
routing, the counting core, the classifier functions, the report pipelines, the
option parser, the cleanup trap, and the test harness. The capstone assembles the
same moves into one small tool of your own — and holds it to the bar logsleuth meets.

---

## The reference tool

`labs/capstone/lab.sh` installs logsleuth and proves every property the course
taught — all twenty-two checks:

- **installs and runs from your PATH** (`install.sh` symlinks the entry point,
  which resolves the link to find its `lib/`; man page and completion installed).
- **every subcommand correct** — `summary` (140 requests, 4 IPs, 4xx=50), `top`,
  `errors` (5xx=5), `bruteforce` (flags `203.0.113.9`).
- **exit codes are a usable API** — 0 ok, 1 unreadable file, 2 usage, 3 brute force.
- **composes in pipelines** — reads stdin; its exit 3 drives `|| alert`.
- **correct AND clean** — green test suite, zero shellcheck findings.
- **robust** — repeated stdin runs leak zero temp files; config read as *data*.

Run it:

```bash
bash labs/capstone/lab.sh
```
```text
---- capstone: 22 passed, 0 failed ----
```

---

## Your exercise — build `mytool` to the rubric

Open `labs/capstone/exercise/` and read `TASK.md`. You assemble a tiny
line-analyzer, `mytool`, that scores every row of the rubric:

- strict mode + a temp-file cleanup trap
- `getopts` for `-n`/`-h`; a `case` dispatcher for the subcommand
- reads a FILE **or** stdin
- distinct exit codes: 0 ok, 1 unreadable file, 2 usage / unknown command
- shellcheck-clean

```bash
cd labs/capstone/exercise
bash grade.sh                 # seeds work/ and runs the rubric
# ...fill every # TODO in work/mytool...
bash grade.sh                 # until: ---- capstone: N passed, 0 failed ----
```

---

## Then do it on a project of your own

Write a bash tool you actually want — a backup rotator, a deploy helper, a report
generator — that meets the same rubric:

- [ ] `#!/usr/bin/env bash` + `set -euo pipefail` + a clear `usage()`
- [ ] `getopts` for options, a `case` dispatcher for subcommands
- [ ] logic in functions in a sourced `lib/`, not one long script
- [ ] reads a FILE argument **or** stdin; quotes every expansion
- [ ] distinct exit codes (0 ok / 1 runtime / 2 usage / app-specific)
- [ ] a `trap` that cleans up temp files on any exit, with the code preserved
- [ ] a config file parsed as **data** (never sourced)
- [ ] a test suite (`assert.sh`-style) that is green
- [ ] **zero** shellcheck findings
- [ ] an `install.sh`, a man page, and bash completion

**Pass** = a green `grade.sh` on `mytool`, then the equivalent on your own project:
it works, it's tested, it's lint-clean, and it installs. That is the "hero" the
course set out to reach — not someone who memorized syntax, but someone who ships
bash tools other people can trust.
