# CAP-01 — Capstone: run fraud-clf live with `stackctl`, and hand it over
**FULL TRAINER EDITION · curriculum v2.0.0-draft · assessment time 1.00 h (+ CAP-01R, 0.50 h under observation)**

> **TRAINER ONLY — about this edition.** Student text verbatim; trainer blocks inserted. This page holds the R-11 level descriptors, the scoring procedure with worked arithmetic, calibration samples, the **CAP-01R fault list with injection commands, symptoms and solutions**, and the observation protocol. None of it may reach a student-visible Moodle area.
>
> **Prep.** Do V-04 once yourself (M09 trainer page: `live-smoke.sh test` and `prod` on the reference, `record-manifest.sh`), and keep the two transcripts and the manifest. You will need: (1) your own digest for `nginx:1.27-alpine` *per architecture* to compare learner manifests against — the serve image ID is **not** comparable across machines (see the M09 trainer page, S09.7); (2) a feel for how long the first `up` takes on your network (pip install of scikit-learn/pandas plus training; the learner's `WAIT_TIMEOUT=120` may be too short on a slow link — that is why the warm-up `up` is untimed and outside the transcript; a timeout there is not a learner error if the retry succeeds). **Review time:** ≈25 min per learner for CAP-01 (transcript, files, note), ≈30 min live for CAP-01R.
>
> **Evidence boundary (decide before the cohort starts).** Without a reviewer who reads the transcript and observes CAP-01R, the result is *self-assessed* (blueprint §6). Grader output from the mock driver is never CAP-01 evidence; a transcript is. Accept a terminal recording (asciinema, screen capture) in place of `script` output. A transcript that has been edited after the fact is a Not met on every criterion it supports — look for prompts and timestamps that do not line up, and for `plan` output whose indentation differs from the tool's.
>
> **Program hand-off.** A pass here is Course 2 Module 0 done early; record it so the Course 2 instructor can skip that module's "run the baseline" step for this learner and start from their *Inherited findings* list.


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


> **TRAINER ONLY — what a correct transcript contains (designed; confirm against your V-04 run).** Step 3: `validate` → `ok: test → project fraudclf-test on port 18080 (serve fraudclf-serve:m0 built from app/, gateway nginx:1.27-alpine, health GET /api/health)` (the `warning:` about the tag-only gateway pin on the *first* run, none on the re-run after step 7; the `note:` about the local serve image on every run); `plan` → `up would: create project fraudclf-test (2 services)`; `up` → `up: test (… wait ≤ 120s)` then `up: done — 2 of 2 services running` (fast, because the warm-up built the image); `check` → `check: http://127.0.0.1:18080/api/health → [{"status":"ok"}] ok`; `status` → two indented service names (`gateway`, `serve`); second `plan` → `up would: nothing — converged`; second `up` → `done — 2 of 2`; `curl` health → `{"status":"ok"} status=0`; `curl` predict → `{"probabilities":[[0.9…,0.0…]]}` — two numbers summing to 1; the exact values depend on the training data regenerated at build and are not graded. Step 4: the same for `prod` on 18081; `docker compose ls` shows both projects `running(2)`. Step 5: two refusals with `status=2`, one `destroy: project fraudclf-test removed …` with `status=0`, `docker compose ls` still listing `fraudclf-prod`. Step 6: `# 34 passed, 0 failed` and `== live smoke OK ==` (the live smoke also prints one prediction). Step 7: a manifest with, per environment, one `IMAGE_GATEWAY … → nginx@sha256:…` line and one `IMAGE_SERVE fraudclf-serve:m0 → sha256:… (local build of APP_DIR/Dockerfile.course)` line.
>
> **Things that legitimately differ between machines:** the gateway digest per architecture; the serve image ID on every machine and every rebuild; Compose version line; `up` duration; the predict probabilities (regenerated training data, pip-resolved scikit-learn version); on a Mac without the GNU tools and the Homebrew `flock` (Environment section 3 step 6), the `sed -i ''` form and a lock that cannot be taken — accept a documented container run of the lock-dependent commands only in that case; on Windows 11 everything runs inside WSL 2 Ubuntu, so the transcript looks like Ubuntu's.

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


> **TRAINER ONLY — level descriptors.**
> - **R-11.1 Live operation (4).** *Strong:* transcript shows the full `test` then `prod` sequence in the stated order, both `up`s healthy, both `check`s `[{"status":"ok"}] ok`, a predict call answered on both, `docker compose ls` listing both projects, `curl` on both ports. *Met:* both environments were brought up and checked, but out of order, or `status`/`ls`/predict missing, or one environment was brought up only after the other was destroyed (isolation not demonstrated). *Not met:* one environment never reached `check` ok live.
> - **R-11.2 Exact health (2).** *Strong:* live `check` 0 **and** the mock suite's four `check` cases (0/3/3/1) pass, and `cmd_check` uses a byte-exact capture and `HEALTH_PATH`. *Met:* live check 0 but the capture is a plain `$( )` (passes the real body, would pass it with a trailing newline) — the mock suite shows `check with the body plus a newline → 3` failing. *Not met:* `check` compares with `grep`/substring, hard-codes `/api/health`, or does not distinguish unreachable (1) from mismatch (3).
> - **R-11.3 Validate first; plan pure (3, critical).** *Strong:* dispatcher runs validation before every command, `plan` renders only to `$WORK`, mock suite `plan makes no mutating call` and `validation precedes mutation` pass, and D1/D2 show the learner knows why. *Met:* passes the checks but `plan` writes into `.render/` (a mutation of the applied snapshot — the grader cannot see this; read `cmd_plan`) or `up` validates only when called directly. *Not met:* any `up`/`down` call reachable before validation, or `plan` that calls `up`.
> - **R-11.4 Idempotency (2, critical).** *Strong:* second `plan` says `converged`, second `up` is in the transcript and recreated nothing (Compose prints `Running` rather than `Recreated`/`Created` for both services), and D1 names the change `plan` cannot see (a rebuilt `app/` under the same tag). *Met:* second `up` succeeded but `plan` reported drift because of a self-inflicted render-path difference (S09.4) which the learner explains. *Not met:* second `up` recreated services or failed, or the step is missing.
> - **R-11.5 Destroy safety (3, critical).** *Strong:* the two refusals and one success in the transcript, `docker compose ls` proving `prod` survived `test`'s destroy, `down -v` scoped by `--project-name`, and `grep -r prune` over the tree empty. *Met:* refusals correct but the proof that the other environment survived is missing. *Not met:* any accepted confirmation other than the exact environment name, or any `docker system prune`/`docker volume prune` in the tree or the transcript.
> - **R-11.6 Tests (3).** *Strong:* `# 34 passed, 0 failed` and `== live smoke OK ==` both in the transcript, unmodified `tests/`. *Met:* both pass but `tests/run.sh` was edited (compare with the starter: added skips or removed cases are a Met at best; ask why). *Not met:* either suite missing or failing.
> - **R-11.7 Handover (3, critical for fabricated values / modified app / real secrets).** *Strong:* runbook meets the LAB-09c *Met* bar or better including section 6, `MANIFEST.txt` is the unedited output of `record-manifest.sh`, confs carry the `@sha256:` gateway pin that matches the manifest, re-run `validate` shows no tag-only warning, `diff -r work/app starter/app` is empty. *Met:* manifest present but confs still tag-only, or runbook has a thin section 6. *Not met (critical):* a digest or image ID that is not in the learner's own manifest/transcript, or a gateway digest that does not match your V-04 digest for the same architecture without an explanation (different architecture is a legitimate reason — ask); a modified `app/` (the "fix" that belongs to Course 2); or any *real* token, password or private key in any file or transcript. The planted `AKIAIOSFODNN7EXAMPLE` pair in `app/config.py` is the baseline's, is AWS's documented example key, and is **not** a finding against the learner — it is a finding they must list.
> - **R-11.8 Decisions note (6).** *Strong:* all three answers name the mechanism (below) in the learner's own words with a reference to their own transcript. *Met:* two of three at mechanism level, or three answers that are correct but generic. *Not met:* fewer than two mechanism-level answers, or text that reads as pasted documentation.
>
> **Model answers.**
> - **D1 — Met:** in my code, `up` renders the same files from the same conf, and `plan` compares the new render with `.render/test/` byte for byte (`diff -q` on `stack.yml` and `gateway.conf`) and counts running services, so it prints `nothing — converged`; in Compose, `up` compares each service's definition with the running container's and leaves unchanged services alone. What `plan` cannot see: a change inside `app/` — the image name `fraudclf-serve:m0` is the same, so the render is identical while the image that would be built is not. **Strong:** adds that Compose prints `Running` for untouched services, that the bind-mount and build-context paths are deliberately rendered as stable paths so the two renders are identical, or that the manifest records the image *ID* precisely because the tag cannot carry that information.
> - **D2 — Met:** `CONFIRM_DESTROY` must equal the selected environment name (protects against destroying the wrong environment or running a generic `yes`), and the lock must be free (protects against destroying while another operator's `up` is mid-flight). **Strong:** adds that the `down -v` is scoped by `--project-name`, so even a confirmed destroy cannot touch `prod`, that there is no prune for the same reason, or that Course 2's promotion approval is the same gate with a human in it.
> - **D3 — Met:** the gateway digest from `docker image inspect --format '{{index .RepoDigests 0}}'` and the serve image ID from `--format '{{.Id}}'`, both run by `tools/record-manifest.sh` on the machine that pulled and built the images; a copied value is a claim without an observation — the grader cannot tell, so the course treats it as fabricated evidence, the same rule as "observed vs designed" throughout. **Strong:** adds that a digest is per platform/architecture or that a tag can move while a digest cannot, and that the serve image has *no* digest anywhere because it was never pushed — its ID exists only on the machine that built it.
>
> **Scoring procedure (≈25 min).** 1) Read `TRANSCRIPT.txt` top to bottom once, ticking the steps. 2) `cd work && bash tests/run.sh | tail -1 && grep -rn prune bin lib tests; diff -r tests ../starter/tests; diff -r app ../starter/app` (expect no prune, no diffs). 3) Open `envs/*.conf` and `MANIFEST.txt`; compare the gateway digest with the manifest and with your V-04 digest; check the serve ID is 64 hex digits and appears in the live transcript's build. 4) Level each criterion; compute `Σ weight × level / 2`; apply the critical gates; pass ≥ 20.8 → **21/26**. 5) Write feedback per criterion below Strong.
>
> **Worked arithmetic.** All Strong = 26/26. Everything Strong but no note: 20/26 = 76.9% → fail (R-11.8 Not met is not critical, but the total is under 80%). Everything Strong, note Met: 23/26 = 88% → pass. R-11.1 Met (isolation not shown), R-11.7 Met (tag-only confs), rest Strong: 26 − 2 − 1.5 = 22.5/26 = 86.5% → pass, with feedback. All Met: 13/26 = 50% → fail — the same convention as A-10 (Met means a warned-against deviation). Any critical Not met → fail regardless (e.g., 24/26 with a pasted digest, or with `config.py` "fixed" → fail).
>
> **Calibration.** *D1 Strong:* "My `plan` diffs the fresh render against `.render/test/stack.yml` and `gateway.conf` — they're identical because the mount path and build context are rendered as fixed paths either way — and `compose ps` says 2 running, so it prints converged. Compose's own `up` showed `Container fraudclf-test-serve-1 Running` the second time: it compared the container config with the file and left it. If I edited `app/serve.py` nothing would change in the render, so `plan` would still say converged — that's why the manifest keeps the image ID." *D1 Not met:* "Because Compose is idempotent." (no mechanism, nothing about the tool).
>
> **Remediation map.** R-11.3/11.4 → S09.3–S09.4 and LAB-09b; R-11.5 → S09.5 (and R2 of LAB-09b); R-11.2 → S09.6; R-11.7 → S09.7 and LAB-09c (and `COURSE0-NOTE.md` for a modified `app/`); R-11.6 → M08 (reading a suite) then LAB-09b; R-11.8 → the module's "Why" paragraphs, then rewrite the note from the transcript, not from memory. **Re-attempt:** same rubric; a fresh transcript is required — the previous one cannot be reused.
>
> **Evidence handling.** Keep `TRANSCRIPT.txt`, `MANIFEST.txt`, `DECISIONS.md`, the two conf files, the `diff -r app` result and the rubric sheet; the rest of the tree is reproducible from them plus the grader. Strip nothing from transcripts (the planted example keys may appear if a learner `cat`s `config.py`; that is fine and expected).

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


> **TRAINER ONLY — fault list, injection, symptoms, solutions.** Prepare a *copy* of the learner's own green tree: `cp -r work cap01r && cd cap01r && rm -rf .render envs/*.lock`, then `sed -i 's/^PORT=18080/PORT=28080/; s/^PROJECT=fraudclf-test/PROJECT=fraudclf-r-test/' envs/test.conf` and `sed -i 's/^PORT=18081/PORT=28081/; s/^PROJECT=fraudclf-prod/PROJECT=fraudclf-r-prod/' envs/prod.conf` (BSD `sed -i ''` only on a Mac without the GNU tools). Inject **one** fault from the tier you chose; the learner is told only "one environment is altered". Faults marked *observed* were reproduced with the reference and the mock driver (2026-10-21); the rest are *designed* and need a daemon — run them yourself once before using them.
>
> | Tier | ID | Injection (in `cap01r/`) | Symptom the learner must read | Correct diagnosis and fix | Status |
> |---|---|---|---|---|---|
> | A (config) | F1 | `sed -i 's/^PORT=28080/PORT=280a80/' envs/test.conf` | `stackctl: PORT must be a number, got: 280a80`, exit **2** from `validate`/`up`, no `up` call made | validation error: non-numeric port; fix the conf line, `validate` → 0 | observed |
> | A | F2 | `sed -i '/^HEALTH_BODY/d' envs/test.conf` | `…/envs/test.conf: missing required key: HEALTH_BODY`, exit 2 | required key deleted; restore `HEALTH_BODY={"status":"ok"}` | observed |
> | A | F3 | `sed -i 's/^HEALTH_BODY=.*/HEALTH_BODY={"status": "ok"}/' envs/test.conf` (a space after the colon) | `check: … returned [{"status":"ok"}], expected [{"status": "ok"}]`, exit **3**; `validate` shows the tell too (`health GET /api/health = '{"status": "ok"}'` in `plan`) | the *expected* contract was edited, the app is right; fix the conf, `check` → 0 | observed (mock); live designed |
> | A | F8 | `sed -i 's|^HEALTH_PATH=.*|HEALTH_PATH=/health|' envs/test.conf` | `validate` prints `health GET /health` (the tell); live: nginx proxies `/health` to the app, which answers 404 → `curl: (22) … 404` then `unreachable`, exit **1** — not 3 | the path, not the body: the app serves `/api/health`; fix the conf, `check` → 0 | validate tell observed; live effect observed against a local HTTP server, designed against the stack |
> | B (cross-env) | F4 | `sed -i 's/^PROJECT=fraudclf-r-prod/PROJECT=fraudclf-r-test/' envs/prod.conf` | `validate -e prod` prints `ok: prod → project fraudclf-r-test on port 28081` (the tell); live: `up -e prod` **recreates** `test`'s project with the prod port, then `check -e test` → `unreachable`, exit **1**, and `docker compose ls` shows a single project | both environments share a project name — the isolation invariant is broken; fix `PROJECT=fraudclf-r-prod`, `up -e test` (restores 28080), `up -e prod`, `check` both | validate tell observed; live effect designed |
> | C (runtime) | F5 | `sed -i 's/serve:8080/serve:8081/' compose/gateway.conf.tmpl` | `validate` → 0 (shape is fine); `plan` shows drift in the `proxy_pass` line (observed); live: the gateway healthcheck (through the proxy) fails → `--wait` times out, `up` exit **1**; `logs` shows nginx `connect() failed … upstream` | the gateway points at the wrong upstream port; fix the template, `up`, `check` | plan drift observed; live designed |
> | C | F6 | in a second terminal the trainer runs `( exec 9>envs/test.lock; flock 9; sleep 600 ) &` | `up`/`destroy` → `test is locked by another stackctl run (…/envs/test.lock); try again later`, exit **1** immediately; `fuser envs/test.lock` shows a PID | another holder; identify it (`fuser`/`lsof`), confirm it is not a real operator, end it, re-run | observed |
> | C | F7 | `sed -i 's/^IMAGE_GATEWAY=nginx:1.27-alpine$/IMAGE_GATEWAY=nginx:1.27-alpnie/' envs/test.conf` (only if the tag is not already pinned by digest; needs network) | `validate` → 0; `up` → pull error from Compose (`manifest … not found`), exit **1**; `logs` empty for `gateway` | tag typo → image not pullable; fix the conf, `up` | designed |
> | C | F9 | `mv app/Dockerfile.course app/Dockerfile.course.bak` | `stackctl: APP_DIR app/ has no Dockerfile.course — is the fraud-clf app copy in place?`, exit **2** from every command | the build recipe is missing; restore the file, `validate` → 0 — and note that nothing was mutated because validation refused first | observed |
>
> **Equivalence rule.** First attempt and reassessment use **different faults from the same tier** (A: F1/F2/F3/F8/F9 — F3 and F8 are the instructive pair, body vs path; B: F4 alone — for a reassessment of F4 use F5; C: F5/F6/F7). Tier A is appropriate where the cohort is entry-level; tier C where learners have a daemon and network; never give F7 offline.
>
> **Observation protocol (≈30 min).** 1) Say only: "one environment in this copy is altered; find it, tell me what it is before you fix it, fix it, prove it with `check`." 2) Start timing at the first command. 3) Do not answer questions about the fault; you may answer questions about the tool's documented behavior (the module page) — note that you did. 4) Record: the exact line of output the learner cited, the sentence in which they named the cause, whether the fix was targeted (one change) or exploratory (several), and the final `check` line. 5) Stop at 30 min; an unfinished attempt is scored on what was said and shown.
>
> **R-12 descriptors.** **R-12.1 Located and explained (4, critical).** *Strong:* names the fault, the exit code and the output line that revealed it *before* editing anything; for F4 also names the broken invariant (two environments, one project); for F3 vs F8 says which side — contract or route — is wrong. *Met:* names the fault after one wrong guess that the tool's own output immediately refuted. *Not met:* fixes by trial and error, or names the fault only after the stack is healthy, or "fixes" `app/` to match a wrong conf. **R-12.2 Fixed and verified (3, critical).** *Strong:* one targeted change, then `validate`/`up`/`check` as appropriate, ending in `check: … → [{"status":"ok"}] ok`; for F4 verifies **both** environments. *Met:* fixed with extra, harmless changes, verified with `check`. *Not met:* `check` never run, or "it works" asserted from `up` alone. **R-12.3 Runbook (2).** *Strong:* the case was already in the runbook or is added with the symptom line, code and fix. *Met:* added in prose without the exit code. *Not met:* not added. Pass = ≥ 7.2 → **8/9** with both critical ≥ Met.
>
> **Calibration (F8).** *Strong:* "`check` exits 1, not 3, and curl said 404 — so nothing is wrong with the body, the path is wrong: `validate` prints `health GET /health` and the app only has `/api/health`. The fault is `HEALTH_PATH` in `test.conf`." *Not met:* learner edits `app/src/serve.py` to add a `/health` route so the check passes — the stack ends healthy and the learner has modified the inherited app to fit a broken config.

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


> **TRAINER ONLY — course close.** Record CAP-01 (score, critical gates, evidence location) and CAP-01R (fault ID, time, R-12 levels). Completion wording: "self-assessed" unless a reviewer scored R-11 and observed R-12. Pass the learner's *Inherited findings* list to the Course 2 instructor — it is their Module 0 output. Open verification tasks at release: V-01 (image build), V-02 (install docs/licensing access dates), V-03 (manual citations), V-04 (your own live run of the reference — do it before the first cohort), V-05 (pilot). Maintenance triggers that touch this page: Compose `--wait` semantics, the nginx tag, `python:3.12-slim` and the baseline's `requirements.txt` (a pip resolution change can break the build — pin in `Dockerfile.course` if it does, and record it), and any change to the baseline repo's `/api/health` response.
