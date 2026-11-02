# Bash Scripting — zero to hero, project-based

A gold-standard bash course that takes you from "what is a shebang" to a
packaged, tested, lint-clean command-line tool — by building **one real project**
across ten labs. Every lesson is graded by a script you run yourself, **offline,
with only bash + coreutils** (shellcheck recommended).

Read `course-content/README.md` for the course overview and the lesson pages.

## The project: `logsleuth`

A log-analysis CLI a security or platform engineer would keep — it reports top
talkers, error spikes, and **brute-force source IPs** in web access logs and
sshd auth logs. It grows across the course from a one-line skeleton into a tool
with subcommands, a config file, strict-mode safety, traps, a test suite, bash
completion, a man page, and an installer. Every bash concept is taught where
`logsleuth` needs it.

## What it covers

Foundations & strict mode · variables, quoting & parameter expansion ·
conditionals & `case` · loops, `while read -r` & **associative arrays** ·
functions & sourced libraries · the **text-processing toolkit** (grep/cut/sort/
uniq/sed/awk, pipes, here-docs, process substitution) · arguments & `getopts` ·
**robustness** (traps, signals, `mktemp`, `flock`, the `set -e` footguns) ·
**testing & shellcheck** · packaging. Then a capstone that installs and proves
the whole tool, and sets you the same bar on a tool of your own.

## Layout

```
README.md                 this file
tools-check.sh            confirm bash + coreutils + awk/sed/grep (shellcheck recommended)
grade-all.sh              YOUR dashboard: grades the exercises you build
prove_all.sh              run every lab walkthrough + exercise solution + the suite; ALL GREEN
seed/make_logs.sh         deterministic fixture logs with exact, documented counts
labs/
  _lib.sh                 shared harness for the worked lab.sh walkthroughs
  _exercise.sh            shared harness for the student exercises (grade YOUR work/)
  lab0-first-script/      shebang, exit codes, strict mode, shellcheck
    lab.sh                the worked, self-grading walkthrough
    exercise/             TASK.md + starter/ (you edit) + solution/ + grade.sh
  lab1-variables/         quoting, command substitution, parameter expansion, arithmetic
  lab2-conditionals/      [[ ]] vs [ ], file/string/number tests, case
  lab3-loops-arrays/      for, while read -r, indexed + associative arrays, mapfile
  lab4-functions/         local, status vs output, sourced libraries
  lab5-text-processing/   grep/cut/sort/uniq/sed/awk, pipes, here-docs, process substitution
  lab6-arguments/         positional params, getopts, subcommands, stdin-or-file, exit codes
  lab7-robustness/        set -e pitfalls, trap EXIT/INT/TERM, mktemp cleanup, flock
  lab8-testing/           a test harness, unit + black-box tests, shellcheck gate, set -x
  capstone/               install + prove the whole tool end to end
logsleuth/                the finished project the labs build and exercise
  bin/logsleuth           strict mode, getopts, case dispatch, cleanup trap (symlink-safe)
  lib/{util,parse,report}.sh
  etc/logsleuth.conf      KEY = VALUE, parsed as data (never sourced)
  tests/                  assert.sh + unit/black-box tests + run.sh
  completions/logsleuth.bash   bash completion
  man/logsleuth.1         the manual
  install.sh              onto PATH, with man page + completion
course-content/           the ILM-format lesson pages (one per lab) + overview
```

## Two ways through each part

1. **You build it.** Each part has a hands-on lesson and a matching exercise under
   `labs/<lab>/exercise/`. You implement the real logsleuth piece in a starter file
   (the key lines are marked `# TODO`), and a grader checks *your* work:
   ```bash
   cd labs/lab3-loops-arrays/exercise
   bash grade.sh            # seeds work/ from the starter, grades it (FAILs first)
   # ...edit work/counters.sh, then re-run until 0 failed...
   ```
   `bash grade-all.sh` from the root is your dashboard across every exercise.
2. **The worked answer.** Each `labs/<lab>/lab.sh` is a runnable walkthrough that
   also self-grades — read it beside the lesson, or check it after your exercise.

## Run it

```bash
bash tools-check.sh
bash grade-all.sh                       # YOUR exercises (edit work/, then re-run)
bash prove_all.sh                       # ALL GREEN: walkthroughs + exercise solutions + suite
bash labs/lab3-loops-arrays/lab.sh      # one worked walkthrough
bash logsleuth/tests/run.sh             # the project's own test suite
```

`prove_all.sh` is green when every lab walkthrough passes, every exercise's
reference solution passes, the `logsleuth` suite is green, and shellcheck finds
nothing. Your `grade-all.sh` goes green once *you* have completed the exercises.

## Status

Built and fully verified offline: **10 student exercises you build (68 checks) +
10 worked walkthroughs (194 checks) + 17 project tests, 0 failures**, the whole
`logsleuth` tree shellcheck-clean, idempotent from a clean run. Requires only bash ≥ 4 (associative arrays; macOS ships 3.2 — `brew install
bash`), coreutils, and awk/sed/grep; shellcheck and `flock` are used by the
quality and robustness labs.

## Use the tool for real

```bash
cd logsleuth && PREFIX=~/.local ./install.sh      # onto your PATH
logsleuth summary /var/log/nginx/access.log
logsleuth -n 5 top /var/log/nginx/access.log
logsleuth bruteforce /var/log/auth.log || echo "ALERT: brute force detected"
```
