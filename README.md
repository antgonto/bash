# Bash Scripting — zero to hero, project-based

**Course 0 of the SecMLOps program.** The shell every `ci/*.sh`, `scripts/*.sh` and
`Makefile` in Courses 1–3 is written in, taught on the program's own project: `logsleuth`
reads the fraud-clf gateway log in M01–M08, and `stackctl` (M09, capstone) builds and runs
the inherited fraud-clf baseline with validate → plan → apply.

This repository is the **authoring source**. It is private because it holds trainer-only
material (reference solutions, graders' answer keys, rubric descriptors, the blueprint, the
maintenance manifest). Learners never see this tree; they get **built archives**, and
`tools/leakcheck.sh` verifies that no trainer material reaches a student archive.

The course lives in two directories that together make one course:

| Directory | What it is | Who edits it |
| --- | --- | --- |
| [`bash-course-v2/`](#bash-course-v2--the-written-course) | The **written** course: lesson pages (Student + Trainer), environment guide, blueprint, manifest, build tools | Authors |
| [`bash-course/`](#bash-course--the-executable-bundle) | The **executable** bundle: labs, graders, reference solutions, the `logsleuth` project, the program's real scripts, the proof suite | Authors; learners run it |

The pages in `bash-course-v2/` point at the labs in `bash-course/` by path
(`labs/lab5-text-processing/exercise/`), and the packaging step copies `bash-course/` into
every archive, so a learner always has pages and labs side by side.

---

## Quick start

```bash
# Prove the executable bundle: 11 walkthroughs, 11 graders against the reference
# solutions, the logsleuth suite (17 tests) and the whole-project shellcheck gate.
cd bash-course && bash prove_all.sh            # expect the final line: ALL GREEN

# Build the eight distribution archives (student/trainer × master/Ubuntu/macOS/Windows),
# each student archive leak-checked.
cd ../bash-course-v2 && bash tools/package-all.sh
ls dist/                                       # bash-course-v2-{student,trainer}{,-ubuntu,-macos,-windows}.zip
```

Requirements for authoring: bash ≥ 5, GNU coreutils/gawk/sed/grep, `shellcheck`, `jq`,
`python3`, `zip`. The course container (`bash-course-v2/env/Dockerfile`) has all of them.

---

## `bash-course-v2/` — the written course

```
bash-course-v2/
├── README-STUDENT.md          # the README shipped at the root of every student archive
├── README-TRAINER.md          # the README shipped at the root of every trainer archive
├── 00-BRIEF-AND-BLUEPRINT.md  # TRAINER-ONLY: parameters, skills model, traceability, course map,
│                              #   assessment plan, capstone contract, quality gates, open V-tasks
├── CONTINUATION-MANIFEST.md   # TRAINER-ONLY: the authoring record — every batch, every decision,
│                              #   every correction, Notion page IDs, how to publish; START HERE to maintain
├── env/
│   ├── Dockerfile             # the learner image (bash 5, shellcheck, jq, python3, make, flock)
│   └── README.md              # "Environment (Docker) — setup": full step-by-step install per OS,
│                              #   written with <!-- os:… --> markers (see Platform editions)
├── student/                   # the Student Edition pages — the all-platform MASTER
│   ├── M00-orientation-and-first-script.md
│   ├── M01 … M08 (core modules)
│   ├── A10-integrative-practical-mytool.md
│   ├── M09-infrastructure-from-bash.md
│   └── CAP01-capstone-stackctl.md
├── trainer/                   # the Full Trainer Edition pages — GENERATED, do not edit (except M00)
│   ├── M00 … CAP01            # student text verbatim + TRAINER ONLY callouts
│   ├── callouts/              # the trainer-only source: one file per module, anchored to headings
│   └── a10r/                  # the A-10R reassessment kit (task, grader, starter, solution)
└── tools/
    ├── merge_trainer.py       # student page + callouts → trainer page
    ├── build_os.py            # master → one platform edition (resolves markers + os-variants.json)
    ├── os-variants.json       # exact-text and regex variants per OS
    ├── package.sh             # one edition → student + trainer zips (copies bash-course/ in)
    ├── package-all.sh         # all editions → dist/, with leak checks
    └── leakcheck.sh           # asserts a student archive contains no trainer material
```

### How a page is structured

Every module page follows one shape: outcome → activity context (where to run, starting
state, validation status) → numbered steps `S<module>.<n>` (purpose, exact action, expected
observation **as observed**, verification, recovery, evidence) → worked demonstration →
the graded exercise `LAB-<n>` → knowledge checks → *In the SecMLOps Program* (where the
skill reappears in Courses 1–3, often with a *Read the real thing* exercise over a script in
`bash-course/program/`) → recap → self-check answers.

### Editing rules

1. **Edit `student/*.md` and `trainer/callouts/*.md` only.** Regenerate the trainer page:
   `python3 tools/merge_trainer.py student/M05-text-pipelines.md trainer/callouts/M05.callouts.md > trainer/M05-text-pipelines.md`
   (`package-all.sh` does this for every module; `M00` is hand-merged and edited directly in both editions).
2. **Every "observed" output must have been observed.** Run the command, paste what it printed.
   Content that needs a Docker daemon is labelled *designed* and listed under the V-tasks in the manifest.
3. **Platform-specific text** goes in `<!-- os:ubuntu macos -->…<!-- /os -->` blocks (block or inline form)
   or in `tools/os-variants.json`; never in a per-OS copy. The build fails if a variant no longer
   matches exactly once, so a master edit cannot silently ship stale platform text.
4. **Trainer-only text** is marked `TRAINER ONLY` and lives in `callouts/`, the blueprint, the manifest
   or `labs/*/exercise/solution/`. Never in `student/`. `tools/leakcheck.sh` enforces this.
5. Record what you did in `CONTINUATION-MANIFEST.md` (the batch log at the top and the
   *Corrections* section), and republish the changed Notion pages (page IDs and method are in the manifest).

### Platform editions

The master tree is the single source. `tools/build_os.py --os ubuntu|macos|windows --out build/<os>`
copies it, resolves the markers and variants, regenerates the trainer pages and stamps the edition.
Only Environment, M00, M01, M03, M09 and CAP-01 differ between editions. `package-all.sh` builds
all four (master + three) and runs `leakcheck.sh` on each student zip.

---

## `bash-course/` — the executable bundle

```
bash-course/
├── README.md                  # the bundle's own README (project, concepts, how to run)
├── prove_all.sh               # TRAINER-ONLY: runs everything below and ends ALL GREEN or fails
├── grade-all.sh               # LEARNER: grades every labs/*/exercise/work/ in one go
├── tools-check.sh             # LEARNER: is this shell ready? (bash 5, coreutils, shellcheck, jq, python3, make)
├── course-content/            # the v1 lesson pages (part0…part7, capstone) — superseded by
│                              #   bash-course-v2/student/, kept because the v1 Notion course links to them
├── seed/make_logs.sh          # deterministic fixture generator (the fraud-clf gateway log + sshd log,
│                              #   140 lines, documented counts) — every grader regenerates from it
├── labs/
│   ├── _lib.sh                # shared assertion harness for the walkthroughs
│   ├── _exercise.sh           # shared harness for the graders
│   ├── lab0-first-script/ … lab8-testing/, lab9-stackctl/, capstone/
│   │   ├── lab.sh             # LEARNER: the worked demonstration — runs the module's concepts
│   │   │                      #   and asserts the observed counts (student-visible, except capstone/lab.sh)
│   │   └── exercise/
│   │       ├── TASK.md        # LEARNER: the graded exercise (LAB-<n>, assessed as A-<n>)
│   │       ├── grade.sh       # LEARNER: the grader — fills work/ from starter/ on first run
│   │       ├── starter/       # LEARNER: the file(s) with # TODOs the learner completes in work/
│   │       └── solution/      # TRAINER-ONLY: the reference solution (grader passes 100 % on it)
│   └── lab9-stackctl/exercise/{starter,solution}/app/
│                              # the inherited fraud-clf baseline (Course 2 m0) + Dockerfile.course —
│                              #   SHIPPED UNMODIFIED; a modified app/ is a critical failure in CAP-01
├── logsleuth/                 # the course project at its finished state: bin/, lib/, etc/, tests/,
│                              #   completions/, man/, install.sh — M01–M08 build toward this
└── program/                   # read-only copies of the program's REAL scripts (Course 1 infra,
    │                          #   Course 2 ci/), for the "Read the real thing" exercises; not run here
    ├── README.md              # which file comes from where and which module reads it
    ├── ci/                    # sarif_gate.sh, validate_unauth.sh, deploy.sh, versions.env, so_upload.sh
    ├── scripts/               # replica-check.sh, ready-check.sh
    ├── Makefile               # Course 1's lab Makefile
    └── fixtures/              # COURSE-AUTHORED samples in the shapes those scripts read
                               #   (SARIF, a SecObserve-style list, a DSSE attestation envelope)
```

### How a learner uses it

```bash
bash tools-check.sh                          # ready?
bash labs/lab5-text-processing/lab.sh        # watch the module's concepts run (expect "20 passed, 0 failed")
cd labs/lab5-text-processing/exercise
bash grade.sh                                # first run copies starter/ → work/ and reports what fails
#   …edit work/reports.sh until…
bash grade.sh                                # ---- lab5: 5 passed, 0 failed ----
cd ../../.. && bash grade-all.sh             # every exercise at once
```

Graders are deterministic (fixtures regenerated from `seed/`), need only bash + coreutils
(shellcheck recommended), and never read `solution/`.

### How an author uses it

```bash
bash prove_all.sh      # every lab.sh; every grade.sh on its starter (expected failures) and on its
                       # solution (must be 100 %); the logsleuth suite; shellcheck over the project
```

If you change a lab, change `starter/`, `solution/`, `grade.sh` and the matching page in
`bash-course-v2/student/` together, then run `prove_all.sh` and `package-all.sh`.
The observed counts quoted on the pages (e.g. "`---- lab5: 0 passed, 5 failed ----` on the starter")
must still match.

---

## What is built, and what ships where

| Content | Student archive | Trainer archive |
| --- | --- | --- |
| `README-STUDENT.md` / `README-TRAINER.md` | ✔ (student) | ✔ (trainer) |
| `student/` pages, `env/` | ✔ | ✔ |
| `trainer/` pages, `trainer/callouts/`, `trainer/a10r/`, blueprint, manifest | ✘ | ✔ |
| `labs/*/lab.sh`, `exercise/{TASK.md,grade.sh,starter/}`, `grade-all.sh`, `tools-check.sh` | ✔ | ✔ |
| `labs/*/exercise/solution/`, `labs/capstone/lab.sh`, `prove_all.sh` | ✘ | ✔ |
| `logsleuth/`, `seed/`, `program/` | ✔ | ✔ |

`dist/` and `build/` are generated and git-ignored.

---

## Where things are published

The course is also published as Notion trees (a Student and a Trainer tree, each in a master
and three per-OS copies) under *SecMLOps Program → Bash Scripting*; the Student trees are what
gets copied into MoodleCloud. Notion sharing is not the access control — Moodle enrollment is.
Page IDs, the publishing method and its quirks are recorded in
`bash-course-v2/CONTINUATION-MANIFEST.md` (*Notion locations*).

The program repositories this course reads from: `antgonto/secmlops-infra` (Course 1),
`antgonto/secmlops-app` and `antgonto/secmlops-project-{github,gitlab,azure}` (Course 2).
