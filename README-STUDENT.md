# Bash Scripting — zero to hero, project-based · Student Edition

Course 0 of the SecMLOps program · self-paced, no fixed duration · entry level ·
Ubuntu/Debian, macOS (Intel & Apple Silicon), Windows 11 via WSL 2 Ubuntu.

You learn bash by building one real tool, `logsleuth`, which analyses the logs of the program's
fraud-detection API, and you finish by running that API on your own laptop with a second tool
you write, `stackctl`.

## Start here

1. Open `env/README.md` and set up your environment (about an hour the first time).
2. Open `student/M00-orientation-and-first-script.md` and follow the pages in this order:
   `M00 → M01 → M02 → M03 → M04 → M05 → M06 → M07 → M08 → A10 → M09 → CAP01`.
3. Each page ends with a lab. The labs are in `labs/`; the page tells you which one.

## What is in this folder

| Path | What it is |
| --- | --- |
| `student/` | The twelve lesson pages. Every step says what to type, what you will see, and what to do if you see something else. |
| `env/` | The course Docker image (`Dockerfile`) and the step-by-step setup guide (`README.md`). |
| `labs/lab0-first-script/` … `labs/lab8-testing/` | One lab per module M00–M08. |
| `labs/capstone/` | The A-10 integrative practical (`mytool`). |
| `manuals/student/` | A printable PDF manual for every lab: topology, steps with expected output, what to do when something differs, the reflection questions and the rubric. |
| `labs/lab9-stackctl/` | The M09 lab and the CAP-01 capstone (`stackctl`). Its `starter/app/` is the program's fraud-clf API, unchanged — you operate it, you do not edit it. |
| `logsleuth/` | The finished `logsleuth` tool. The lessons take it apart; it is course material, not an answer key. |
| `program/` | Real scripts from Course 1 and Course 2, copied here read-only so some lessons can say "open the real thing". Do not edit them. |
| `seed/make_logs.sh` | Generates the log files the labs analyse. |
| `tools-check.sh` | Checks that your shell has what the course needs. Run it first. |
| `grade-all.sh` | Grades every lab at once — your progress dashboard. |

## How a lab works

```bash
bash labs/lab5-text-processing/lab.sh          # the module's demonstration; ends with "20 passed, 0 failed"
cd labs/lab5-text-processing/exercise
cat TASK.md                                    # what to build
bash grade.sh                                  # first run copies starter/ to work/ and shows what fails
#   edit the files in work/ ...
bash grade.sh                                  # until: ---- lab5: 5 passed, 0 failed ----
```

## Three rules

- Outputs marked **observed** were produced by the authors; outputs marked **designed** need a running
  Docker daemon and were not. Your own run is the evidence for those.
- Never copy a digest from a document into a manifest. Record it from `docker image inspect` on your machine.
- AI assistance is allowed when you say so in your reflection. A-10's decisions note and CAP-01R are in your own words.

This package contains no solutions and no trainer material.
