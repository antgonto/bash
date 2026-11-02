# Bash Scripting — zero to hero, project-based

This is the source of the Bash Scripting course (Course 0 of the SecMLOps program).

The repository is **private** because it contains the answers: reference solutions, grading
keys and trainer notes. Learners never get this repository. They get **zip archives** that are
built from it, and a check (`tools/leakcheck.sh`) makes sure the student archives contain no answers.

## The two folders

The course is split in two folders. Together they make one course.

| Folder | Contains | In one sentence |
| --- | --- | --- |
| `bash-course-v2/` | The **lessons** (text) and the build tools | What the learner **reads** |
| `bash-course/` | The **labs**, their graders, the course project, and the proof suite | What the learner **runs** |

The lessons refer to the labs by path, for example `labs/lab5-text-processing/exercise/`.
When the archives are built, `bash-course/` is copied inside them, so a learner has the lessons
and the labs side by side.

---

## I am a learner — how do I use this?

You should be using a zip archive, not this repository. Inside the archive:

1. Open `README-STUDENT.md`.
2. Follow the pages in `student/` in order: `M00`, `M01` … `M08`, `A10`, `M09`, `CAP01`.
3. Each page has a lab. Labs live in `labs/`. For example, module 5 uses `labs/lab5-text-processing/`:

```bash
bash tools-check.sh                             # 1. Is my shell ready?
bash labs/lab5-text-processing/lab.sh           # 2. Watch the module's demo run. It ends with "20 passed, 0 failed".
cd labs/lab5-text-processing/exercise
bash grade.sh                                   # 3. First run: creates work/ from starter/ and shows what fails.
#    Edit the files in work/ until...
bash grade.sh                                   # 4. ---- lab5: 5 passed, 0 failed ----
```

`bash grade-all.sh` (at the top of the archive) grades every lab at once.

---

## I am a trainer — how do I use this?

Use the **trainer** zip archive. It has everything the student archive has, plus:

- `trainer/` — every lesson page again, with orange **TRAINER ONLY** boxes: teaching notes,
  the complete solution, how to grade, and the answers to the knowledge checks.
- `labs/*/exercise/solution/` — the reference solution for every lab.
- `prove_all.sh` — runs every lab and every grader to prove the course still works.
- `00-BRIEF-AND-BLUEPRINT.md` — the course design (skills, assessment plan, open verification tasks).

---

## I am an author — how do I change the course?

### Changing a lesson

1. Edit the page in `bash-course-v2/student/`. That is the only copy of the student text.
2. Trainer notes go in `bash-course-v2/trainer/callouts/` (one file per module), never in `student/`.
3. Rebuild the trainer page from those two files:

```bash
cd bash-course-v2
python3 tools/merge_trainer.py student/M05-text-pipelines.md trainer/callouts/M05.callouts.md > trainer/M05-text-pipelines.md
```

(`M00` is the exception: it is edited by hand in both `student/` and `trainer/`.)

4. Every command output shown on a page as **observed** must really have been observed. Run the
   command and paste what it printed.

### Changing a lab

Change these four things together, in `bash-course/labs/<lab>/exercise/`:
`starter/` (what the learner gets), `solution/` (the answer), `grade.sh` (the grader), and the
matching page in `bash-course-v2/student/`. Then prove it:

```bash
cd bash-course && bash prove_all.sh             # must end with: ALL GREEN
```

### Building the archives

```bash
cd bash-course-v2 && bash tools/package-all.sh
ls dist/
```

This produces eight archives: `student` and `trainer`, each in four versions — the all-platform
master, Ubuntu, macOS and Windows 11. Every student archive is leak-checked.

The platform versions are **generated**; do not edit them. Platform-specific text is written in the
master pages inside `<!-- os:ubuntu macos -->` … `<!-- /os -->` blocks, or in `tools/os-variants.json`.

### Recording your change

Write what you did in `bash-course-v2/CONTINUATION-MANIFEST.md`. It is the course's logbook:
every change so far, every decision, every correction, and the IDs of the Notion pages to republish.

---

## What is in `bash-course-v2/`

| Path | What it is |
| --- | --- |
| `student/` | The twelve lesson pages: `M00`–`M08` (core bash), `A10` (integrative practical), `M09` (infrastructure from bash: `stackctl`), `CAP01` (capstone). **The master copy of the course text.** |
| `trainer/` | The same twelve pages with trainer-only boxes added. **Generated** from `student/` + `trainer/callouts/`. |
| `trainer/callouts/` | The trainer notes, one file per module. **Edit these, not `trainer/*.md`.** |
| `trainer/a10r/` | The reassessment kit for A-10 (a second, equivalent exam). |
| `env/Dockerfile`, `env/README.md` | The learner's Docker image and the step-by-step setup guide for Ubuntu, macOS and Windows 11. |
| `README-STUDENT.md`, `README-TRAINER.md` | The README placed at the root of each archive. |
| `00-BRIEF-AND-BLUEPRINT.md` | The course design document. Trainer-only. |
| `CONTINUATION-MANIFEST.md` | The logbook. Trainer-only. Read it first when maintaining the course. |
| `tools/merge_trainer.py` | Builds a trainer page from a student page and its callouts. |
| `tools/build_os.py`, `tools/os-variants.json` | Build one platform version from the master. |
| `tools/package.sh`, `tools/package-all.sh` | Build the zip archives. |
| `tools/leakcheck.sh` | Fails if a student archive contains trainer material. |

## What is in `bash-course/`

| Path | What it is | Who sees it |
| --- | --- | --- |
| `labs/lab0-first-script/` … `labs/lab8-testing/` | One folder per core module. | everyone |
| `labs/lab9-stackctl/`, `labs/capstone/` | The M09 lab and the A-10 capstone. | everyone (except `capstone/lab.sh`, trainer-only) |
| `labs/<lab>/lab.sh` | The module's worked demonstration. Runs the concepts and checks the results. | everyone |
| `labs/<lab>/exercise/TASK.md` | The graded exercise. | everyone |
| `labs/<lab>/exercise/starter/` | The files with `# TODO`s. The learner completes a copy in `work/`. | everyone |
| `labs/<lab>/exercise/grade.sh` | The grader. | everyone |
| `labs/<lab>/exercise/solution/` | The reference solution. | **trainer only** |
| `labs/lab9-stackctl/exercise/*/app/` | The fraud-clf application from Course 2, unchanged. `stackctl` runs it. Learners must not modify it. | everyone |
| `logsleuth/` | The course project in its finished form: a log-analysis command-line tool with a library, tests, a config file, a man page and an installer. Modules 1–8 build toward it. | everyone |
| `program/` | Real scripts from Course 1 and Course 2, copied here read-only so that lessons can say "open the real thing". `program/README.md` lists where each comes from. | everyone |
| `seed/make_logs.sh` | Generates the log files the labs analyse. Same output every time, so graders are reliable. | everyone |
| `tools-check.sh` | Checks that the shell has what the course needs. | everyone |
| `grade-all.sh` | Runs every lab's grader. | everyone |
| `prove_all.sh` | Runs every demo, every grader on starter and solution, the `logsleuth` tests and shellcheck. | **trainer only** |
| `course-content/` | The lesson pages of the **old version 1** of the course. Kept only because the old Notion pages link to them. Not used by version 2. | — |

---

## Where the course is published

- **Notion:** a Student tree and a Trainer tree under *SecMLOps Program → Bash Scripting*, each in a
  master and three platform copies. The Student trees are what gets copied into MoodleCloud.
  Moodle enrollment is the access control, not Notion sharing.
- **Archives:** built from this repository with `tools/package-all.sh` (`dist/` is not committed).
- **Program repositories this course reads from:** `antgonto/secmlops-infra` (Course 1),
  `antgonto/secmlops-app` and `antgonto/secmlops-project-{github,gitlab,azure}` (Course 2).
