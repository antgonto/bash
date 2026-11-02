# Bash Scripting — zero to hero, project-based

You learn bash by building one real tool, end to end, and every lesson is graded
by a script you run yourself — **offline, no accounts, no setup beyond bash**.
The course goes from "what is a shebang" to a packaged, tested, lint-clean CLI
with a man page and bash completion.

## The project

The running project is **`logsleuth`** — a log-analysis command-line tool a
security or platform engineer would actually keep. It reports on web access logs
and sshd auth logs: top talkers, error spikes, and **brute-force source IPs**.
Across the course it grows from a one-line skeleton into a tool with subcommands,
a config file, strict-mode safety, traps, a test suite, and an installer.

Every bash concept is taught where `logsleuth` needs it: associative arrays
because the brute-force scan counts failed logins per IP; `getopts` because the
CLI has options; traps because the tool must never leak a temp file. You build
each piece, then an autograder confirms the real tool agrees with you.

## The path (zero to hero)

| Lab | You learn | logsleuth gains |
|---|---|---|
| **0 · First script** | shebang, execution, exit codes, `printf`, **strict mode**, shellcheck | a runnable skeleton (`version`/`help`) |
| **1 · Variables** | quoting (the #1 footgun), command substitution, **parameter expansion**, arithmetic | config values, report filenames |
| **2 · Conditionals** | `if`, `[[ ]]` vs `[ ]`, file/string/number tests, `&&`/`||`, **`case`** | input validation + subcommand routing |
| **3 · Loops & arrays** | `for`, **`while read -r`**, indexed and **associative arrays**, `mapfile` | the per-IP brute-force counter |
| **4 · Functions** | parameters, `local`, status vs output, **sourced libraries** | the `lib/` refactor (util/parse/report) |
| **5 · Text processing** | **grep, cut, sort, uniq -c, sed, awk**, pipes, here-docs, process substitution | the `top`/`summary`/`errors` reports |
| **6 · Arguments** | positional params, **`getopts`**, subcommands, stdin-vs-file, exit codes as API | the full command line |
| **7 · Robustness** | strict-mode pitfalls, **`trap`** on EXIT/INT/TERM, `mktemp` cleanup, `flock` | signal-safe cleanup + preserved exit codes |
| **8 · Testing & quality** | a test harness, unit + black-box tests, **shellcheck as a gate**, `set -x` | a green test suite + a lint gate |
| **Capstone** | the whole tool, installed and proven; your own tool to the same bar | installer, man page, completion |

## How each part works

Every part has two halves:

- **A hands-on lesson** (these pages) — a step-by-step build: edit, run, read the
  exact output, understand why. Part 0 builds a usable `greet` from an empty file;
  Parts 1–8 each build a real piece of logsleuth.
- **An exercise you complete** under `labs/<lab>/exercise/` — you implement that
  piece in a starter file (key lines marked `# TODO`) and a grader checks *your*
  work:
  ```bash
  cd labs/lab3-loops-arrays/exercise
  bash grade.sh      # seeds work/ from the starter, grades it (FAILs first)
  # ...edit work/counters.sh, then re-run until 0 failed...
  ```

## Run it

```bash
bash tools-check.sh    # confirms bash + coreutils + awk/sed/grep (shellcheck recommended)
bash grade-all.sh      # YOUR exercises across every part (edit work/, then re-run)
bash prove_all.sh      # walkthroughs + exercise solutions + the suite; expect ALL GREEN
bash labs/lab3-loops-arrays/lab.sh    # a worked, self-grading walkthrough
```

Alongside each exercise, `labs/<lab>/lab.sh` is the **worked walkthrough** — the
same moves, runnable and self-grading, to read beside the lesson or check your
answer against. The finished tool lives in `logsleuth/`.

## How a lesson is written

Each page is a numbered, hands-on build: short steps of *edit → run → read the
output → why*, closing with **Your exercise** (the piece you implement and grade)
and how it becomes part of `logsleuth`. The goal is never the syntax alone — it is
*why* robust scripts are written this way and *what the program does* at each step.

## A note on quality

The course holds itself to the bar it teaches: the whole `logsleuth` tree is
**shellcheck-clean**, runs under `set -euo pipefail`, cleans up after itself on
any signal, parses its config as *data* (never `source`-ing it), and ships a test
suite. The labs prove each of these, not just describe them.
