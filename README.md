# Bash Scripting — zero to hero, project-based

Course 0 of the SecMLOps program. You learn bash by building one real tool, `logsleuth`, which
analyses the logs of the program's fraud-detection API, and you finish by running that API on your
own laptop with a second tool you write, `stackctl`. Twelve modules, twelve labs, every lab graded by
a script you run yourself. Self-paced, no fixed duration. Works on Ubuntu/Debian, macOS (Intel and
Apple Silicon) and Windows 11 (inside WSL 2 Ubuntu).

**This repository is the whole course**: the lessons, the labs and their graders, the course project,
the environment, the trainer material and the tools that build the distributable archives. Nothing
lives anywhere else. The same content is published in Notion for reading and for copying into
Moodle; this repository is where it is edited and where it runs.

> The repository is private because it also contains the answers (`labs/*/exercise/solution/`,
> `trainer/`). Learners are given a **student archive** built from it (see *Building the archives*),
> which contains no answers. If you give a learner access to this repository instead, you are giving
> them the solutions.

---

## Contents

```
.
├── student/                  the twelve lesson pages — read these in order
├── labs/                     one folder per lab: demonstration, exercise, grader, solution
├── manuals/                  printable lab manuals (PDF): student/ for learners, instructor/ for trainers, src/ is their source
├── logsleuth/                the course project, finished
├── env/                      the course Docker image and the step-by-step installation guide
├── program/                  real Course 1 / Course 2 scripts, read-only, for "read the real thing" exercises
├── seed/                     generates the log files the labs analyse
├── tools-check.sh            checks that your shell has what the course needs
├── grade-all.sh              grades every lab at once
├── trainer/                  the lesson pages with TRAINER ONLY boxes; callouts/ is their source; a10r/ is the reassessment kit
├── prove_all.sh              proves the whole course still works (trainers and authors)
├── tools/                    builds the trainer pages, the platform editions and the archives
├── BLUEPRINT.md              the course design (trainer-only)
├── CONTINUATION-MANIFEST.md  the logbook of every change (trainer-only; read first when maintaining)
├── README-STUDENT.md         the README placed in the student archive
└── README-TRAINER.md         the README placed in the trainer archive
```

Each lesson page has one lab:

| Lesson page (`student/`) | Lab folder (`labs/`) | Graded as |
| --- | --- | --- |
| `M00-orientation-and-first-script.md` | `lab0-first-script/` | A-01 |
| `M01-variables-and-parameter-expansion.md` | `lab1-variables/` | A-02 |
| `M02-conditionals.md` | `lab2-conditionals/` | A-03 |
| `M03-loops-and-arrays.md` | `lab3-loops-arrays/` | A-04 |
| `M04-functions-and-libraries.md` | `lab4-functions/` | A-05 |
| `M05-text-pipelines.md` | `lab5-text-processing/` | A-06 |
| `M06-command-line-and-getopts.md` | `lab6-arguments/` | A-07 |
| `M07-robustness.md` | `lab7-robustness/` | A-08 |
| `M08-testing-and-quality.md` | `lab8-testing/` | A-09 |
| `A10-integrative-practical-mytool.md` | `capstone/` | A-10 |
| `M09-infrastructure-from-bash.md` | `lab9-stackctl/` | LAB-09a/b/c |
| `CAP01-capstone-stackctl.md` | `lab9-stackctl/` (your finished `stackctl`, run live) | CAP-01 |

Every lab also has a printable manual in `manuals/`, in the layout of a networking-academy lab guide
(topology, environment table, objectives, background, numbered parts and steps with expected output, a
symptom table, reflection questions, hand-in and rubric). `manuals/student/<lab>.pdf` is the learner's
copy; `manuals/instructor/<lab>-instructor.pdf` adds, in gray boxes, the instructor notes, the model
answers, the grading procedure and the reference solution.

Every lab folder has the same layout:

```
labs/lab5-text-processing/
├── lab.sh                  the module's demonstration: run it and watch the concepts work
└── exercise/
    ├── TASK.md             what to build
    ├── grade.sh            the grader
    ├── starter/            the files with # TODOs
    ├── work/               created by grade.sh on first run — this is where you edit
    └── solution/           the reference solution (trainer material)
```

---

## Installing the course

You need **Docker** and about 4 GB of free disk. Modules M00–M08 run inside a small container
(`bash-course:2.0`) so everyone has the same bash and tools; M09 and the capstone run in your own
shell and use Docker to run the program's project.

`env/README.md` is the full installation guide — every command for every platform, with what you
should see after each step. In short:

1. **Get the course files.** Either clone this repository or unzip an archive:

   ```bash
   mkdir -p ~/secmlops && cd ~/secmlops
   git clone https://github.com/antgonto/bash.git bash-course && cd bash-course
   ```

   On Windows 11 do this inside the Ubuntu (WSL 2) window, under your Linux home (`~`), never under `/mnt/c`.

2. **Install Docker** for your platform — `env/README.md` section 2 (Ubuntu/Debian: Docker Engine
   from Docker's apt repository), section 3 (macOS: Docker Desktop, plus bash 5 and the GNU tools
   from Homebrew) or section 4 (Windows 11: WSL 2 Ubuntu, then Docker Engine inside it).

3. **Check Docker works** — section 5:

   ```bash
   docker version && docker compose version && docker run --rm hello-world
   ```

4. **Build the course image once** — section 6:

   ```bash
   docker build -t bash-course:2.0 env/
   ```

5. **Start a lab session** (every time you study) — section 7:

   ```bash
   docker run --rm -it -v "$PWD":/course -w /course bash-course:2.0
   bash tools-check.sh                 # the last line must begin with: ready
   ```

   You are now inside the container, in the course folder; your files stay on your computer. Type
   `exit` to leave.

**No Docker?** Modules M00–M08 need only bash ≥ 4, coreutils, awk/sed/grep and, recommended,
shellcheck, flock, jq, curl, python3 and make — `env/README.md` section 8 shows how to install them
on each platform. M09 and the capstone need Docker.

---

## Using the course

### As a learner

1. Set up the environment as above and open a lab session.
2. Read `student/M00-orientation-and-first-script.md`, then the pages in this order:
   `M00 → M01 → M02 → M03 → M04 → M05 → M06 → M07 → M08 → A10 → M09 → CAP01`.
3. Each page ends with a lab. Run the demonstration, then build the exercise until the grader passes:

   ```bash
   bash labs/lab5-text-processing/lab.sh          # the demonstration; ends with "20 passed, 0 failed"
   cd labs/lab5-text-processing/exercise
   cat TASK.md                                    # what to build
   bash grade.sh                                  # first run copies starter/ to work/ and shows what fails
   #   edit the files in work/ ...
   bash grade.sh                                  # until: ---- lab5: 5 passed, 0 failed ----
   ```

4. `bash grade-all.sh` from the course folder shows the status of every lab.
5. If you prefer a printed guide, each lab's manual is in `manuals/student/`.

Every page tells you what to type, what you will see (outputs marked **observed** were produced by
the authors; outputs marked **designed** need a running Docker daemon and are confirmed by your own
run), and what to do if you see something else.

### As a trainer

Everything a learner has, plus:

- `trainer/*.md` — each lesson page with 🧑‍🏫 **TRAINER ONLY** boxes: preparation with the observed
  grader counts, a facilitation plan, per-step teaching notes, the complete solution, grading
  descriptors (Not met / Met / Strong), worked scoring, calibration samples, remediation and an
  equivalent reassessment, and the answers to the knowledge checks.
- `labs/*/exercise/solution/` — the reference solution of every lab.
- `manuals/instructor/` — the instructor version of every lab manual (model answers, grading, solution).
- `trainer/a10r/` — the A-10R reassessment kit.
- `prove_all.sh` — run it before a cohort; it must end with `ALL GREEN`.
- `BLUEPRINT.md` — the course design and the verification tasks still open (V-01…V-05).

`README-TRAINER.md` lists what to do before a first cohort.

### As an author

**Change a lesson.** Edit the page in `student/` — the only copy of the student text — and, if needed,
the trainer notes in `trainer/callouts/`. Then rebuild the trainer page:

```bash
python3 tools/merge_trainer.py student/M05-text-pipelines.md trainer/callouts/M05.callouts.md > trainer/M05-text-pipelines.md
```

`M00` is the exception: edit it by hand in both `student/` and `trainer/`. Every output a page shows as
**observed** must really have been observed — run the command and paste what it printed.

**Change a lab.** Change `starter/`, `solution/`, `grade.sh` and the lesson page together, then:

```bash
bash prove_all.sh                               # must end with: ALL GREEN
```

**Change a lab manual.** Edit `manuals/src/<lab>.md` (student and instructor text in one file;
`:::instructor … :::` and `:::answer … :::` blocks appear only in the instructor PDF), then rebuild:

```bash
python3 tools/build_manuals.py            # all manuals → manuals/student/ and manuals/instructor/
python3 tools/build_manuals.py lab5       # one of them
```

**Record the change** in `CONTINUATION-MANIFEST.md`, then republish the changed Notion pages (the
page IDs and the method are in the manifest).

---

## Building the archives

```bash
bash tools/package-all.sh        # → dist/bash-course-{student,trainer}{,-ubuntu,-macos,-windows}.zip
```

Eight archives: **Student** (no solutions, no trainer material) and **Trainer** (everything), each as
the all-platform master and as three platform editions — Ubuntu/Debian, macOS, Windows 11 — whose
only differences are the setup commands and platform notes in `env/README.md`, M00, M01, M03, M09 and
CAP-01. The editions are generated by `tools/build_os.py` from `<!-- os:… -->` markers in the pages
and from `tools/os-variants.json`; never edit them by hand. `tools/leakcheck.sh` fails the build if a
student archive contains any solution, trainer page, `TRAINER ONLY` text, scratch file or digest.
`dist/` and `build/` are not committed.

A learner who receives `bash-course-student-macos.zip` unzips it and follows its `README.md`, which
is `README-STUDENT.md` from this tree.

---

## Where else the course is

- **Notion** — *SecMLOps Program → Bash Scripting*: a Student tree and a Trainer tree, each in a
  master and three platform versions, generated from these pages. The Student trees are what gets
  copied into MoodleCloud. Moodle enrollment is the access control.
- **Related repositories** — the scripts in `program/` come from `antgonto/secmlops-infra` (Course 1)
  and `antgonto/secmlops-app` / `antgonto/secmlops-project-{github,gitlab,azure}` (Course 2).
