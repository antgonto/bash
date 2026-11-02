# Course 0 — Bash Scripting for the SecMLOps program · v2 (Full Trainer Edition)

Curriculum 2.0.0-draft. This package contains everything in the Student Edition
**plus** the material that must never reach a student-visible area.

## Trainer-only material (keep out of student Moodle areas)
- `trainer/*.md` — every module and assessment page reproduced verbatim with 🧑‍🏫 **TRAINER ONLY** blocks: prep with observed grader counts, facilitator pathways, per-step teaching notes, complete solutions, Met/Strong/Not-met descriptors, scoring procedures with worked arithmetic, calibration samples, model feedback, remediation and equivalent reassessments.
- `trainer/callouts/` — the source of those blocks; `tools/merge_trainer.py STUDENT CALLOUTS` rebuilds a trainer page mechanically (parity is checked by stripping the callouts and diffing).
- `trainer/a10r/` — the A-10R reassessment kit (`linetool`): grader, starter, reference solution, task.
- `labs/*/exercise/solution/` — reference solutions for LAB-00…LAB-09 and A-10.
- `labs/capstone/lab.sh` — the A-10-scope walkthrough.
- `prove_all.sh` — runs every walkthrough, every grader against its reference solution, the `logsleuth` suite and the shellcheck gate; must print `ALL GREEN`.
- `trainer/CAP01-capstone-stackctl.md` — the CAP-01R fault list with injection commands and solutions; `00-BRIEF-AND-BLUEPRINT.md` — the resolved brief, skills model, traceability, time budget, assessment plan, capstone contract, gates and verification tasks; `CONTINUATION-MANIFEST.md` — the authoring record.

## Before the first cohort
1. `bash prove_all.sh` on your machine (expect `ALL GREEN`; 2026-10-19: 11 walkthroughs, 11 graders, 17 project tests, shellcheck clean).
2. Verification tasks still open at release — do them once and record dates in the blueprint §13: **V-01** build `env/Dockerfile` and run `tools-check.sh` + `prove_all.sh` inside it; **V-02** check current Docker install/licensing pages; **V-03** attach GNU Bash manual / ShellCheck wiki citations; **V-04** run `labs/lab9-stackctl/exercise/solution/tests/live-smoke.sh` for `test` and `prod` and `tools/record-manifest.sh` on a daemon machine with network (the first `up` builds the fraud-clf image) (the M09 and CAP-01 trainer pages depend on it); **V-05** pilot with learners.
3. Decide the evidence boundary (blueprint §6): who reviews A-10/CAP-01 and observes CAP-01R. Without a reviewer, completion is "self-assessed".

## Packaging
`bash tools/package.sh` builds `dist/bash-course-v2-student.zip` and `dist/bash-course-v2-trainer.zip` from this tree and the v1 executable bundle, then runs `tools/leakcheck.sh` on the student archive (fails on any solution, trainer page, callout, A-10R kit, capstone walkthrough, `TRAINER ONLY` text, stray `work/`/`.render/`/lock files, or a 64-hex digest anywhere).

## Platform editions

This archive is one edition of the course. `tools/package-all.sh` builds the all-platform master and three platform editions — Ubuntu/Debian, macOS, Windows 11 (WSL 2 Ubuntu) — from the same source (`tools/build_os.py`, `tools/os-variants.json`, marker blocks in `env/README.md`). `EDITION.txt`, when present, names this one. Edit only the master and rebuild; the platform editions differ from it only in Environment, M00, M01, M03, M09 and CAP-01.
