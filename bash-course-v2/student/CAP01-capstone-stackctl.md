# CAP-01 — Capstone: run fraud-clf live with `stackctl`, and hand it over
**Student Edition · curriculum v2.0.0-draft · assessment time 1.00 h (+ CAP-01R, 0.50 h under observation)**

**What this is.** The summative check for LO-10, LO-11 and LO-12, and the point
where Course 0 hands you to the rest of the program. You take the `stackctl` you
finished in LAB-09 and operate the program's project **for real**: a machine with
a Docker daemon, environment `test` then `prod`, every command in the lifecycle,
a prediction through the gateway, the test suites, and the two handover documents
— recorded in a transcript. Nothing from the mock driver counts as evidence here.
A second, shorter part (**CAP-01R**) puts one deliberately broken environment in
front of you to locate, explain and fix while a trainer watches.

**Prerequisite check.** LAB-09a/b green (`---- lab9: 34 passed, 0 failed ----`),
LAB-09c runbook without `TODO`, A-10 passed, and a host with `docker info`
succeeding (Docker Desktop running on macOS; Docker Engine on Ubuntu or in WSL 2
Ubuntu on Windows 11) and network access for the first image build.

---

## Assessment context

| Field | Value |
|---|---|
| Location | Your `labs/lab9-stackctl/exercise/work/` tree, on a host with a running daemon |
| Time | 60 minutes, self-timed, **after** a first `up` has built the serve image (that build is not timed — do it before you start the transcript): ≈35 min live operation, ≈15 min tests and manifest, ≈10 min decisions note |
| Allowed resources | The module pages, Docker documentation, AI assistance **for documentation lookup only** (say so in the note); **not** `solution/`, and not another learner's tree |
| Deliverables | the `work/` tree (`bin/`, `lib/`, `envs/*.conf` with the recorded gateway digest, `app/` untouched, `tests/`, `RUNBOOK.md`, `MANIFEST.txt`), `TRANSCRIPT.txt`, `DECISIONS.md` (≈150 words, three answers) |
| Acceptance | the weighted rubric R-11 score is ≥ 80% **and** no *critical* criterion is at Not met |
| Reassessment | CAP-01 may be re-attempted after remediation with the same rubric; CAP-01R has an equivalent variant with a different fault |
| Validation status | The reference `stackctl` passes its mock suite 34/34 and the course grader 34/34 in the authoring environment (observed 2026-10-21); the **live** procedure below was **designed**, not run there (no daemon) — verification task V-04. Your transcript is the first evidence either of us has that it works on *your* machine, which is exactly why it is required |

---

## The task

Operate the program's project through its whole lifecycle, twice, and prove it:

1. **Warm up, untimed.** From `work/`: `bin/stackctl -e test up` once, so the serve image is built and the gateway image pulled (several minutes the first time; `up` may time out while pip installs — run it again). Then `CONFIRM_DESTROY=test bin/stackctl -e test destroy`. Nothing of this goes in the transcript.
2. **Record everything.** Start a transcript before the first timed command: Linux and WSL 2 `script -q TRANSCRIPT.txt`; macOS `script TRANSCRIPT.txt`. Type `exit` when you finish to close it. If `script` is unavailable, copy your terminal into the file by hand — but do not edit what the commands printed.
3. **`test`, in this order**, from `work/`:
   ```bash
   bin/stackctl -e test validate
   bin/stackctl -e test plan
   bin/stackctl -e test up
   bin/stackctl -e test check
   bin/stackctl -e test status
   bin/stackctl -e test plan            # must say: up would: nothing — converged
   bin/stackctl -e test up              # must succeed and change nothing
   bin/stackctl -e test logs | tail -5
   curl -fsS http://127.0.0.1:18080/api/health; echo " status=$?"
   curl -fsS -X POST http://127.0.0.1:18080/api/predict -H 'content-type: application/json' -d '{"instances": [[120.0, 14, 0.2, 1]]}'; echo
   ```
4. **`prod`, the same sequence with `-e prod`** — while `test` is still up. Then show both are isolated: `docker compose ls` lists `fraudclf-test` and `fraudclf-prod`; `curl -fsS http://127.0.0.1:18081/api/health` answers.
5. **Safety, in the transcript:** `bin/stackctl -e test destroy` (must refuse, exit 2); `CONFIRM_DESTROY=prod bin/stackctl -e test destroy` (must refuse, exit 2); then `CONFIRM_DESTROY=test bin/stackctl -e test destroy` (exit 0) and `docker compose ls` showing `fraudclf-prod` **still running**. Finally destroy `prod` the same way. Print `echo "status=$?"` after each of the three destroy attempts.
6. **Tests:** `bash tests/run.sh | tail -1` (`# 34 passed, 0 failed`) and `bash tests/live-smoke.sh test` (ends `== live smoke OK ==`).
7. **Manifest and pins:** `bash tools/record-manifest.sh` → `MANIFEST.txt`; append `@sha256:<digest>` from that output to `IMAGE_GATEWAY` in both conf files; run `bin/stackctl -e test validate` again — the tag-only warning must be gone (the `note:` about the locally built serve image stays; it has no digest to pin).
8. **Handover:** `RUNBOOK.md` complete (LAB-09c), now with section 5 filled from `MANIFEST.txt` and section 6 listing the inherited findings.
9. **`DECISIONS.md`** — about 150 words in total, your own words:
   - **D1.** Your transcript shows `plan` saying `converged` and a second `up` that changed nothing. What in *your code* makes that true, and what in Compose? What change would `plan` *not* have seen?
   - **D2.** `destroy` refused twice before it worked. Name the two conditions it checks and say what each one protects against.
   - **D3.** Where did the gateway digest and the serve image ID in `MANIFEST.txt` come from, and why would copying either from the course page or a chat answer be a critical failure even if the string happened to be correct?

**Hints.** H1: the warm-up `up` is what makes the timed run clean — without it the first `up` in the transcript is a build log. H2: `up` waits up to `WAIT_TIMEOUT` seconds for health; a timeout shows as exit 1 — read `logs` before retrying, and remember the model trains at build time, not at start. H3: port 18080/18081 collisions with another app show up as an `up` failure mentioning `address already in use`; change the port in the conf, `validate`, `plan`, `up`. H4: the predict call returns `{"probabilities":[[p_legit,p_fraud]]}`; any two numbers that sum to 1 are a correct answer from the baseline model.

**Reset.** `CONFIRM_DESTROY=test bin/stackctl -e test destroy; CONFIRM_DESTROY=prod bin/stackctl -e prod destroy; rm -rf .render`.

---

## Rubric R-11 (learner-visible)

Levels **Not met** (0) · **Met** (1) · **Strong** (2), scored `weight × level / 2`.
**Pass** = total ≥ 80% of the maximum (26) **and** no *critical* criterion at Not met.
*Strong* means "built and operated to the standard taught"; *Met* means "works, with a
deviation the module warned about"; *Not met* means the evidence is missing or
contradicts the claim. Detailed level descriptors are in the Trainer Edition.

| ID | Criterion | Evidence | Weight | Critical |
|---|---|---|---|---|
| R-11.1 | Live operation of `test` then `prod`: `up` healthy, `check` ok, a prediction answered, `status`, both projects listed and isolated | transcript steps 3–4 | 4 | — |
| R-11.2 | Health contract is exact: `check` 0 live; mismatch and unreachable distinguished (3 vs 1) | transcript; mock suite | 2 | — |
| R-11.3 | Validation precedes every mutation and `plan` never mutates | code + transcript + mock suite | 3 | **yes** |
| R-11.4 | Idempotency: second `up` succeeds and `plan` reports converged | transcript step 3 | 2 | **yes** |
| R-11.5 | Destroy safety: refuses without `CONFIRM_DESTROY=<this env>`; `down -v` scoped to the project; **no global prune** anywhere | transcript step 5; code | 3 | **yes** |
| R-11.6 | Tests: `tests/run.sh` 34/34 and `live-smoke.sh` OK, both in the transcript | transcript step 6 | 3 | — |
| R-11.7 | Handover: `RUNBOOK.md` complete incl. inherited findings; `MANIFEST.txt` values **recorded** by `record-manifest.sh` on the operating machine; gateway pinned; `app/` untouched; **no real secrets** added anywhere | files + transcript step 7 | 3 | **yes** (fabricated digest or ID, a modified `app/`, or a real secret) |
| R-11.8 | Decisions note: three answers that name the mechanism in your own words | `DECISIONS.md` | 6 | — |

A flawless transcript with no decisions note scores 20/26 = 77% — **not a pass**. The
note is where you show the understanding the transcript cannot. The baseline's
*planted* example keys in `app/config.py` are not "a real secret" — they are an
inherited finding that belongs in your runbook, not a fix you make here.

---

## CAP-01R — under observation (0.50 h)

Your trainer hands you a copy of your own tree with **one** environment altered:
ports `28080`/`28081`, projects `fraudclf-r-test`/`fraudclf-r-prod`, and one
injected fault somewhere in `envs/`, `compose/` or the host state. With the trainer
watching (live or on a recording), you:

1. run the lifecycle until something fails,
2. **say what you think the fault is before you fix it**, naming the exit code and the line of output that told you,
3. fix it, verify with `check` → `[{"status":"ok"}] ok`, and
4. add the symptom and recovery to your `RUNBOOK.md` if it is not there yet.

**Rubric R-12 (learner-visible).** *Critical:* the fault is **located and explained** from the tool's own output before the fix (R-12.1, weight 4); the fix is **verified by `check`** (R-12.2, weight 3). Non-critical: the runbook gains the case or already covered it (R-12.3, weight 2). Pass = ≥ 80% and no critical at Not met. A learner who fixes by trial and error without naming the cause fails R-12.1 even if the stack ends healthy. Reassessment: an equivalent variant with a different fault.

---

## In the SecMLOps Program

Passing CAP-01 means you have already done the first thing Course 2 asks: Module 0,
"run the finished thing", on the inherited `fraud-clf` baseline — and your runbook's
*Inherited findings* is the list its README tells you to keep for the rest of that
course. Course 1 comes next: the same `validate → plan → apply`, lock and named
confirmation, with OpenTofu, Ansible and real machines as the driver.

---

## After CAP-01 — what you can now claim

You have written a tool that builds, provisions, verifies and removes a real
service — the program's own project — from Bash, with the safety properties
professional tooling has, and you have the transcript, tests, runbook and
manifest to show it. The honest scope: a two-service stack on one machine, with
the service's own weaknesses still in place by design. The same skeleton drives a
different driver; the properties do not change. If your completion evidence was
reviewed only by you (self-paced without a reviewer), say "self-assessed" when you
describe it.
