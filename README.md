# Bash Scripting — zero to hero, project-based

Course 0 of the SecMLOps program. You learn bash by building one real tool, `logsleuth`, which
analyses the logs of the program's fraud-detection API, and you finish by running that API on your
own laptop with a second tool you write, `stackctl`.

This repository is the **source of the course**: lessons, labs, graders, solutions and build tools,
all in one tree. It is **private** because it contains the answers. Learners never get this
repository; they get a zip archive built from it, and `tools/leakcheck.sh` guarantees the student
archives contain no answers.

The same course is published in Notion under *SecMLOps Program → Bash Scripting*, as a Student
tree and a Trainer tree. Notion and this repository hold the same content; Moodle enrollment is the
access control.

## The tree

```
.
├── README.md                 this file
├── README-STUDENT.md         the README learners see at the root of their archive
├── README-TRAINER.md         the README trainers see at the root of theirs
├── student/                  the twelve lesson pages — the master copy of the course text
├── trainer/                  the same pages with TRAINER ONLY boxes (generated from student/ + callouts/)
│   ├── callouts/             the trainer notes, one file per module — edit these, not trainer/*.md
│   └── a10r/                 the A-10R reassessment kit
├── env/                      the course Docker image and the step-by-step setup guide
├── labs/                     one folder per lab: a demonstration, the exercise, its grader, its solution
├── logsleuth/                the course project, finished
├── program/                  real Course 1 / Course 2 scripts, read-only, for "read the real thing" exercises
├── seed/                     the log-file generator the labs use
├── tools/                    build tools: trainer pages, platform editions, archives, leak check
├── tools-check.sh            is this shell ready?                      (learners run it)
├── grade-all.sh              grade every lab at once                   (learners run it)
├── prove_all.sh              prove the whole course still works        (trainers and authors)
├── BLUEPRINT.md              the course design                         (trainer-only)
└── CONTINUATION-MANIFEST.md  the logbook of every change               (trainer-only; read first when maintaining)
```

## Lessons and labs

Each lesson page in `student/` has one lab in `labs/`:

| Lesson page | Lab folder | Graded as |
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
| `CAP01-capstone-stackctl.md` | `lab9-stackctl/` (the learner's finished `stackctl`, run live) | CAP-01 |

Every lab folder has the same layout:

```
labs/lab5-text-processing/
├── lab.sh                  the module's demonstration: run it and watch the concepts work
└── exercise/
    ├── TASK.md             the graded exercise
    ├── grade.sh            the grader
    ├── starter/            the files with # TODOs
    ├── work/               created by grade.sh on first run — where the learner edits
    └── solution/           the reference solution (trainer archive only)
```

## I am a learner

Use the zip archive from your course area, not this repository. Then follow `README-STUDENT.md`
inside it: set up the environment with `env/README.md`, read the pages in `student/` in order, and
do each page's lab:

```bash
bash tools-check.sh                             # is my shell ready?
bash labs/lab5-text-processing/lab.sh           # the demonstration; ends with "20 passed, 0 failed"
cd labs/lab5-text-processing/exercise
bash grade.sh                                   # first run creates work/ from starter/ and shows what fails
#   edit the files in work/ ...
bash grade.sh                                   # ---- lab5: 5 passed, 0 failed ----
```

## I am a trainer

Use the **trainer** archive. It is the student archive plus `trainer/` (the lesson pages with
teaching notes, solutions, grading descriptors and knowledge-check answers), every lab's
`solution/`, `prove_all.sh`, `BLUEPRINT.md` and `CONTINUATION-MANIFEST.md`. `README-TRAINER.md`
lists what to do before a first cohort.

## I am an author

**Change a lesson.** Edit the page in `student/` (the only copy of the student text) and, if needed,
the trainer notes in `trainer/callouts/`. Rebuild the trainer page:

```bash
python3 tools/merge_trainer.py student/M05-text-pipelines.md trainer/callouts/M05.callouts.md > trainer/M05-text-pipelines.md
```

`M00` is the exception: it is edited by hand in both `student/` and `trainer/`. Every output a page
shows as **observed** must really have been observed — run the command and paste what it printed.

**Change a lab.** Change `starter/`, `solution/`, `grade.sh` and the lesson page together, then prove it:

```bash
bash prove_all.sh                               # must end with: ALL GREEN
```

**Build the archives.**

```bash
bash tools/package-all.sh                       # → dist/bash-course-{student,trainer}{,-ubuntu,-macos,-windows}.zip
```

Eight archives: Student and Trainer, each as the all-platform master and three platform editions
(Ubuntu/Debian, macOS, Windows 11 via WSL 2 Ubuntu). The platform editions are generated — never
edit them. Platform-specific text goes in the master pages inside `<!-- os:ubuntu macos -->` …
`<!-- /os -->` blocks, or in `tools/os-variants.json`. `dist/` and `build/` are not committed.

**Record the change** in `CONTINUATION-MANIFEST.md`, and republish the changed Notion pages
(the page IDs and the publishing method are in the manifest).

## Related repositories

The scripts in `program/` come from `antgonto/secmlops-infra` (Course 1) and
`antgonto/secmlops-app` / `antgonto/secmlops-project-{github,gitlab,azure}` (Course 2).
