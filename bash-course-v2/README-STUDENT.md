# Course 0 — Bash Scripting for the SecMLOps program · zero to hero, project-based · v2 (Student Edition)

Curriculum 2.0.0-draft · self-paced, no fixed duration · entry level · **Ubuntu/Debian, macOS (Intel & Apple Silicon), Windows 11 via WSL 2 Ubuntu** ·
Docker as the learner environment (M00–M08 inside the course container, M09 on your host).
This is the foundation course of the SecMLOps program: its project analyzes the logs of the program's
fraud-detection API and its capstone, `stackctl`, runs that API (the Course 2 baseline) on your laptop.

## What is in this package
- `student/` — the ten module pages M00–M09 plus the two assessments (A-10, CAP-01). Read them in order; every step says what to run, what you will see, and how to recover.
- `env/` — the course image definition and setup notes (M00 S00.1–S00.3).
- `labs/labN-*/lab.sh` — the worked demonstration for each module (run it; it prints `---- labN: N passed, 0 failed ----`).
- `labs/labN-*/exercise/` — your exercise: `TASK.md`, `starter/`, `grade.sh`. The first `bash grade.sh` copies `starter/` to `work/`; you edit `work/`.
- `labs/capstone/exercise/` — A-10 (`mytool`), and `labs/lab9-stackctl/exercise/` — M09/CAP-01 (`stackctl`; its `starter/app/` is the program's `fraud-clf` baseline, unmodified, plus `Dockerfile.course` — operate it, do not fix it).
- `logsleuth/` — the finished reference tool the modules dissect (course material, not an answer key).
- `seed/make_logs.sh`, `tools-check.sh`, `grade-all.sh` — fixtures, environment check, your exercise dashboard.

## Start here
1. `student/M00-orientation-and-first-script.md` (environment setup and your first script).
2. `bash tools-check.sh` inside the container; then `bash grade-all.sh` any time to see every exercise's status.
3. Module order: M00 → M01 → M02 → M03 → M04 → M05 → M06 → M07 → M08 → A-10 → M09 → CAP-01.

## Rules that keep the evidence honest
- Outputs labeled **observed** were produced in the authoring environment; outputs labeled **designed** need a Docker daemon and were not. Your transcript is the evidence for those.
- Never type a digest from a document into a manifest; record it from `docker image inspect` on your machine.
- AI assistance is allowed in practice when you say so in your reflection; A-10's decisions note and CAP-01R are done in your own words.

This package deliberately contains **no** `solution/` directories and no trainer material. Solutions, level descriptors and reassessment kits are in the Trainer Edition.

**`program/`** — read-only copies of real Course 1 and Course 2 scripts, at their 2026-11-02 state (`ci/sarif_gate.sh`, `ci/validate_unauth.sh`, `ci/deploy.sh`, `scripts/replica-check.sh`, `scripts/ready-check.sh`, …) the Course 1 `Makefile`, plus course-authored fixtures in the shapes they read (SARIF, a SecObserve-style list, a DSSE attestation envelope). M04–M08 end with a "Read the real thing" exercise on them; S01.7, S04.5, S05.6–S05.8, S06.6, S07.6 and S08.5 run the idioms they use (`export` and one-shot environment, `dirname "$0"`, `jq`, here-documents, `curl` status codes, `${1:?…}`, secrets hygiene, bash wrapping Python). They are not run in this course and must not be edited.
