# Lab 9 exercise — `stackctl`: run the program's project from bash

You finish `stackctl`, the tool that operates the SecMLOps program's project —
**fraud-clf**, the fraud-detection API you will take to production in Course 2 —
on your own laptop, the infrastructure-as-code way. Two services per
environment: `serve` (the program's FastAPI model service, built from the
inherited repo copy in `app/`) behind `gateway` (nginx, the only published
port). Two environments, `test` (:18080) and `prod` (:18081), the same pair
Course 2 promotes between. The dispatcher (`bin/stackctl`), the driver
(`lib/driver.sh`, with a **mock** mode so everything is testable without
Docker), the compose and gateway templates, the environment files, the app copy
and the test suite are given. You write the seven functions marked `# TODO` —
three in LAB-09a, four in LAB-09b — then the handover documents in LAB-09c.

## What you build
- **LAB-09a** (`lib/config.sh`, `lib/ops.sh`): `parse_conf` (KEY=VALUE as *data*,
  whitelisted keys, never sourced), `validate_conf` (required keys, PORT range,
  image name shape, `APP_DIR/Dockerfile.course` present, `HEALTH_PATH` shape),
  `cmd_check` (`GET HEALTH_PATH` through the gateway must equal `HEALTH_BODY` —
  `{"status":"ok"}` — byte for byte; exit 3 on mismatch, 1 if unreachable).
- **LAB-09b** (`lib/ops.sh`): `with_lock` (`flock -n` per environment),
  `cmd_plan` (desired vs applied vs running; **never mutates**), `cmd_up`
  (`compose up -d --wait --wait-timeout N`; builds the serve image on the first
  run; re-running converges), `cmd_destroy` (refuses unless
  `CONFIRM_DESTROY=<env>`; `down -v` scoped to the project; never a global prune).
- **LAB-09c**: fill `RUNBOOK.md` (operate / diagnose / recover / inherited
  findings) from your own runs, and on a Docker machine record `MANIFEST.txt`
  with `tools/record-manifest.sh`.

## Do it
1. `bash grade.sh` — seeds `work/` from `starter/` and grades it with the mock driver.
   Expect `---- lab9: 10 passed, 24 failed ----` on the untouched starter.
2. Read `work/app/COURSE0-NOTE.md`: you operate the inherited app, you do not fix it.
3. Work through the `# TODO` comments in `work/lib/config.sh`, then `work/lib/ops.sh`;
   each one lists the exact calls to make. Re-run `bash grade.sh` after every function.
4. Run the tool's own suite too: `bash work/tests/run.sh` (mock driver; prints `# N passed, M failed`).
5. With a Docker daemon available: `bash work/tests/live-smoke.sh test` — the only
   evidence that the stack really builds and provisions — then `bash work/tools/record-manifest.sh`.
6. Replace every `TODO` in `work/RUNBOOK.md` with what you actually observed.

## Rules the grader enforces
`validate`/`plan` make no `up`/`down` call · `up` runs validation first · a second `up`
leaves `plan` saying `up would: nothing — converged` · `check` asks the gateway for
`HEALTH_PATH` and compares bytes · `destroy` refuses without `CONFIRM_DESTROY=<this env>`
and never prunes · a locked environment fails fast with exit 1 · the conf file is parsed,
never `source`d · the runbook has its six sections and no `TODO` · everything is shellcheck-clean.

## Your deliverable
`work/` fully green (`---- lab9: 34 passed, 0 failed ----`), `work/RUNBOOK.md` with
no `TODO`, and — when you have a daemon — `work/MANIFEST.txt` plus the
`live-smoke.sh` transcript (needed for CAP-01).
