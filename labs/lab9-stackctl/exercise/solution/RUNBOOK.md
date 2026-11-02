# RUNBOOK — stackctl (reference; trainer edition)

## 1. What this stack is
The SecMLOps program's project, `fraud-clf`, run locally the way Course 2 later runs it on the lab clusters. Two services per environment: `serve` — the program's FastAPI model service (`GET /api/health`, `POST /api/predict`), built locally from `app/` with `Dockerfile.course` as image `fraudclf-serve:m0`, listening on 8080 inside the project network only — and `gateway` (nginx, pinned image, publishes `127.0.0.1:PORT → 80`, proxies everything to `serve`; it is the only published port, the same shape as Course 2's zero-trust proxy without the identity part). Two environments, each its own compose project so they never share names or ports: `test` → project `fraudclf-test`, port 18080; `prod` → project `fraudclf-prod`, port 18081 — the same `test`/`production` pair Course 2 promotes between. All configuration is in `envs/<env>.conf` (eight whitelisted keys; parsed as data, never sourced). `GET HEALTH_PATH` (`/api/health`) through the gateway must return exactly `HEALTH_BODY` (`{"status":"ok"}`).

## 2. Operate
```
bin/stackctl -e test validate     # parse + range checks + Dockerfile.course present + compose config; exit 2 on any problem; changes nothing
bin/stackctl -e test plan         # desired vs applied vs running, one "up would:" line; changes nothing
bin/stackctl -e test up           # validate, render to .render/test/, compose up -d --wait --wait-timeout 120 (builds serve on the first run)
bin/stackctl -e test check        # GET http://127.0.0.1:18080/api/health must equal {"status":"ok"} byte for byte (3 on mismatch)
bin/stackctl -e test status       # services running in project fraudclf-test
bin/stackctl -e test logs         # last 50 lines (STACKCTL_LOG_LINES to change)
```
Run them in that order; `plan` after `up` must say `up would: nothing — converged`. Repeat with `-e prod`. A prediction through the gateway: `curl -fsS -X POST http://127.0.0.1:18080/api/predict -H 'content-type: application/json' -d '{"instances": [[120.0, 14, 0.2, 1]]}'`.

## 3. Diagnose
- `validate` exits 2 → read the stderr line: it names the file, line and key (`PORT must be 1024–65535`, `unknown key`, `missing required key`, `APP_DIR … has no Dockerfile.course`, `HEALTH_PATH must start with /`). Fix the conf, re-run `validate`.
- `up` exits 1 and says `up failed` → `bin/stackctl -e <env> logs`. On the **first** `up` the serve image is built (pip install + training): a failure there is a build error (no network for pip, a changed requirements line) and shows in the compose output, not in `logs`. A health wait timeout shows `serve` or `gateway` unhealthy: typical causes are the model still training when the timeout is short (raise `WAIT_TIMEOUT`), port already in use on the host (`ss -ltn | grep 18080`), the gateway image tag not pullable (offline / typo), `gateway.conf` not mounted (`.render/<env>/gateway.conf` missing).
- `check` exits 3 → the body differs; the message shows `[got]` vs `[expected]` — look for a trailing newline, spaces inside the JSON, or a different `HEALTH_BODY`. `check` exits 1 → nothing answers on the port: the stack is down (`status`), `PORT` changed since the last `up` (`plan` shows drift), or `HEALTH_PATH` points at a route the app does not serve (nginx answers 404 → curl fails → "unreachable").
- `up` exits 1 immediately with `locked by another stackctl run` → another `up`/`destroy` is running for the same env, or a stale shell still holds `envs/<env>.lock` (find it with `fuser envs/<env>.lock`).

## 4. Recover
- Bad conf: fix `envs/<env>.conf`, `validate`, then `up` (re-running converges; unchanged services are not recreated).
- Unhealthy service: `logs`, fix the cause, `up` again; if the definition changed, `plan` shows `re-render and recreate`. If the serve image must be rebuilt (you changed `app/`): `docker image rm fraudclf-serve:m0`, then `up` builds it again — `plan` cannot see this; the image ID in the manifest will change.
- Rebuild one environment: `CONFIRM_DESTROY=<env> bin/stackctl -e <env> destroy` then `up`. `destroy` is `compose down -v` for that project only; the other environment keeps running. There is deliberately no `docker system prune` in this tool: a global prune would delete images and volumes of every project on the host, including the other environment and the course image.
- Lock stuck: finish or kill the holder; the lock file itself is harmless and can stay.

## 5. Versions and digests
Produce with `bash tools/record-manifest.sh` on the machine that ran the stack and paste its output here, then append `@sha256:<digest>` to `IMAGE_GATEWAY` in each conf. `IMAGE_SERVE` is a local build and has no registry digest; the manifest records its image ID (`docker image inspect --format '{{.Id}}'`), which changes whenever the build changes. This reference checkout has **not** been run against a daemon in the authoring environment (verification task V-04), so no digests or IDs are recorded here; a value that does not come from `docker image inspect` on the operating machine must never be written into this file.

## 6. Inherited findings (for Course 2 — do not fix here)
Observed while reading `app/` as inherited: a hard-coded S3 key pair in `config.py` (Course 2 Milestone 2 moves secrets to OpenBao); `requests==2.19.1` pinned in `requirements.txt` (Milestone 4's SCA gate); `/api/predict` accepts any caller — the gateway publishes it with no authentication (Milestone 10's zero-trust proxy); the model is loaded from whatever `model/model.pkl` contains (Milestone 6 signs the artifact); the image runs as root from `python:3.12-slim` (Milestone 7 hardens it). None of these stop the stack from running; all of them belong on the list the baseline README asks you to keep.
