# Bash Scripting — Zero to Hero, Project-Based (v2)
## Resolved Brief and Blueprint — curriculum version 2.0.0-draft

**Authoring mode:** FULL COURSE, developed in matched Student/Trainer batches.
**Baseline:** the existing course (bundle v1: 10 labs, `logsleuth` project, student
exercises with graders, step-by-step lessons; executed ALL GREEN on 2026-10-16).
**Release status:** design draft → target "ready for pilot" when V-01/V-02 pass.
**This document is Batch 1 of N.** Module M00 (both editions) ships with it; the
continuation manifest lists everything that remains.

---

## 1. Resolved brief

### 1.1 Parameters as supplied (hard constraints)

| Parameter | Value (supplied) |
|---|---|
| COURSE_SUBJECT / TITLE | Bash Scripting — zero to hero, project-based |
| TARGET_CAPABILITY | Students with no previous knowledge become able to **independently create scripts for infrastructure-as-code implementation** |
| AUDIENCE_AND_ENTRY_LEVEL | Entry level; no previous knowledge |
| DURATION_AND_TIME_MODEL | **Self-paced, no fixed duration** (owner, 2026-10-26; supersedes the original 20-hour parameter). Indicative effort per module is kept in §4/§5 as a facilitator planning aid only — it is not a limit and is not shown to learners as a budget |
| DELIVERY_MODE | Self-paced |
| ENVIRONMENT_AND_TOOLSET | Use **Docker containers**; learner platforms are the program's — **Ubuntu/Debian, macOS (Intel & Apple Silicon), Windows 11 via WSL 2 Ubuntu** (owner, 2026-10-21; supersedes the 2026-10-19 macOS+Ubuntu-only decision) |
| AUTHORING_MODE | FULL COURSE — improve the course already published (Notion + bundle v1) |

### 1.2 Resolved interpretation of the capability (design decision — review this first)

"Infrastructure as code" for an entry-level learner, inside a foundations course that
precedes Course 1, cannot honestly mean Terraform, cloud accounts, or Kubernetes. The resolved, feasible capability is:

> **A graduate can independently write, test, and operate robust Bash scripts that
> provision, verify, inspect, and safely tear down *local containerized
> infrastructure* (Docker) in an infrastructure-as-code style — configuration kept
> as data, validation before any mutation, a non-mutating plan, idempotent
> convergence on re-run, exact health verification, per-environment isolation and
> locking, confirmation-gated destruction, distinct exit codes, cleanup traps, and a
> test suite — and can analyze operational logs with shell pipelines.**

This keeps every transferable IaC discipline while bounding the tooling to what a
beginner can run on a laptop. Terraform state, cloud providers, Kubernetes, and
production databases are **excluded**; the course explains how Bash *orchestrates*
such tools without pretending to replace declarative state management.

### 1.3 Assumptions (proposed defaults, labeled; override any of them)

- **A1 Project thread (revised 2026-10-21, owner decision: full program integration).**
  `logsleuth` remains the running project for M00–M08 — built, graded, teaching every
  fundamental — but its fixtures are now the SecMLOps program's: the fraud-clf API's
  gateway log on `staging.secmlops.com` (`/api/health`, `/api/predict`, `/docs`) and the
  Course 1 lab VM's sshd log. Every documented count and IP is unchanged. M09/CAP-01's
  `stackctl` operates the program's project itself (the inherited `fraud-clf` baseline
  behind an nginx gateway, `test`/`prod`), so Course 0 ends where Course 2 Module 0
  begins. Replacing `logsleuth` with an infra project from M00 would still discard
  verified material and make M00–M05 depend on Docker unnecessarily.
- **A0 Position in the program.** This is **Course 0 — Bash foundations** of the
  SecMLOps program: taken before Course 1; its outputs are consumed by Courses 1–3
  (§10 contract table); it never installs anything a later course produces, and later
  courses never re-teach what it covers. The program's host-OS list applies
  (Ubuntu/Debian, macOS Intel & Apple Silicon, Windows 11 via WSL 2 Ubuntu).
- **A2 Where Docker is used.** (a) As the **learner environment**: one course image
  so all learners share bash/tool versions; (b) as the **infrastructure under
  management** in M09/CAP-01. M00–M08 also run without Docker (fallback documented).
- **A3 Help route.** Self-paced with **no guaranteed human instructor**; a facilitator
  pathway is documented. The actual help channel (LMS forum, email) is **to be
  configured by the course owner** — none is invented here.
- **A4 Mastery.** 80/100 with critical gates passed (a starting design choice, not a
  standard). Module exercises are pass/fail by grader (0 failed) plus a reflection.
- **A5 Practical share.** ~57% of non-assessment time is hands-on (see §5); below the
  60% default because true beginners need instruction/demonstration time; the two
  integrative assessments are themselves practical performance.
- **A6 AI use.** Allowed and disclosed during practice; for A-10 and CAP-01 the
  learner must also explain decisions in writing and perform a live change request
  (CAP-01R) — no AI-detection claims.
- **A7 Language.** English; clear, patient, precise.
- **A8 Maintenance owner.** Proposed: the course owner. Quarterly + triggered review.

### 1.4 Conflicts identified and how they are resolved

| Conflict | Resolution | Residual risk |
|---|---|---|
| Zero→IaC in a foundations course | Capability scoped to local containerized infrastructure (§1.2); fundamentals kept lean (verified steps, graders); capstone bounded to a two-service stack. The course has no fixed duration, so depth is bounded by Course 1's needs, not by hours | Pilot may show the indicative effort (§5) is far off; the figures are re-estimated from V-05, nothing is cut to fit them |
| Docker required vs. beginners | Env setup is Step 1 of M00 with a preflight; M00–M08 have a no-Docker fallback | Docker Desktop (macOS) / Docker Engine (Ubuntu, WSL 2) install issues — recovery steps + pointer to primary docs (V-02); macOS system bash 3.2 and missing `flock` handled by the container and documented caveats |
| Validation claims vs. no daemon in authoring env | Pure-bash content: **executed**. Docker-dependent content: **designed + mock-tested**, with verification tasks V-01/V-04 | Live provisioning is unverified until V-04 |
| Self-paced vs. "independently verified mastery" | Graders give self-check mastery; verified mastery requires human/automated review of CAP-01 evidence + CAP-01R | Owner must decide who reviews; otherwise certification claims are limited to self-check |

### 1.5 Exclusions
Terraform/OpenTofu state management, cloud provider accounts, Kubernetes, production
database migrations, CI/CD platform configuration, secrets managers. Each is named in
M09 as "what this discipline becomes at scale," with no hands-on.

### 1.6 Cost and connectivity
No paid services. Docker Desktop licensing varies by organization — learners confirm
current terms (not asserted here). Initial image pulls and the one M09 image build need connectivity; everything
else runs offline.

---

## 2. Skills model

| Skill ID | Authentic task | Observable action | Conditions/tools | Required artifact/behavior | Quality criteria | Target independence | Prereq | Evidence source |
|---|---|---|---|---|---|---|---|---|
| SK-01 | Turn a repeatable command sequence into a runnable script | Create, execute (two ways), lint a script with the strict-mode header | bash ≥4, shellcheck | `greet`: shebang, `set -euo pipefail`, exit 0 | exact output; shellcheck 0 findings | independent | none | S-01 lab0 (executed) |
| SK-02 | Build filenames/values from inputs without corruption | Quote every expansion; apply parameter expansion; parse `key = value` | bash | `stem`, `report_name`, `parse_kv` | grader 7/7 | independent | SK-01 | S-01 lab1 |
| SK-03 | Refuse bad input; route commands | `[[ ]]` tests; `case` dispatch; clear message + non-zero exit | bash | `validate_log`, `route` | grader 7/7 | independent | SK-02 | S-01 lab2 |
| SK-04 | Count "how many of each" in a data file | `while IFS= read -r`; associative arrays | bash | `count_status`, `bruteforce_count` | grader 5/5 | independent | SK-03 | S-01 lab3 |
| SK-05 | Structure code for reuse and testing | Functions with `local`; predicate (status) vs producer (stdout); `source` | bash | `is_valid_status`, `status_class` | grader 9/9 | independent | SK-04 | S-01 lab4 |
| SK-06 | Produce a report from a log | grep/awk/sort/uniq/sed pipelines; process substitution | coreutils, awk | `top_ips`, `count_class` | grader 5/5 | independent | SK-04 | S-01 lab5 |
| SK-07 | Give a tool a real command line | `getopts` with error handling; file-or-stdin; exit codes as API | bash | `parse_opts`, `read_input` | grader 7/7 | independent | SK-05 | S-01 lab6 |
| SK-08 | Make a script safe to schedule | `set -e` edges; code-preserving trap; `mktemp` cleanup; `flock` | bash, util-linux | `worker.sh` | grader 6/6; no temp leak; code preserved | independent | SK-07 | S-01 lab7 |
| SK-09 | Prove a script correct and keep it so | assert harness; unit + black-box tests; shellcheck gate; `set -x` | bash, shellcheck | `assert.sh`; green suite | grader 4/4 | independent | SK-05 | S-01 lab8 |
| SK-10 | Operate a local containerized service from a script | Pin images; `compose config/up --wait/ps/logs/down`; health check with exact body | Docker Engine/Compose | `stackctl up/check/status/logs` | exact health body; converges on rerun | guided→independent | SK-07, SK-08 | S-02 (docs); V-04 (live) |
| SK-11 | Implement an IaC-style change safely | config-as-data (parsed, never sourced); validate→plan→apply; idempotency; per-env lock; confirmation-gated destroy; distinct exit codes | Docker, bash | `stackctl validate/plan/destroy`, `envs/*.conf`, lock files | plan never mutates; destroy requires `CONFIRM_DESTROY=<env>`; no global prune | independent | SK-10 | mock tests (executed); V-04 |
| SK-12 | Diagnose and recover a failing deployment; hand it over | Read logs/exit codes; locate injected fault; fix; document a runbook | Docker, bash | fault fixed; `RUNBOOK.md`; version manifest with *recorded* digests | fault found and explained; no fabricated digest | independent | SK-10, SK-11 | CAP-01R |

**Learning outcomes LO-01…LO-12** map 1:1 to SK-01…SK-12 and are phrased as "The
learner can <observable action> under <conditions> producing <artifact> to <quality>."
Conceptual knowledge required for performance (why quoting matters, why `set -e` is
not universal error handling, what idempotency means) is assessed through the
prediction questions and the written explanations in A-10/CAP-01, not by recall alone.

---

## 3. Traceability matrix

| Authentic task | SK | LO | Module/lesson | Practice (grader) | Assessment | Rubric criterion | Evidence (type) |
|---|---|---|---|---|---|---|---|
| Script a repeatable task | SK-01 | LO-01 | M00 L00.1–L00.7 | LAB-00 `exercise/grade.sh` | A-01 | R-01 output/strict/lint | grader log (direct) |
| Build names/values safely | SK-02 | LO-02 | M01 | LAB-01 | A-02 | R-02 | grader log (direct) |
| Validate + route | SK-03 | LO-03 | M02 | LAB-02 | A-03 | R-03 | grader log |
| Count by key | SK-04 | LO-04 | M03 | LAB-03 | A-04 | R-04 | grader log |
| Structure for reuse | SK-05 | LO-05 | M04 | LAB-04 | A-05 | R-05 | grader log |
| Report from a log | SK-06 | LO-06 | M05 | LAB-05 | A-06 | R-06 | grader log |
| Real command line | SK-07 | LO-07 | M06 | LAB-06 | A-07 | R-07 | grader log |
| Safe to schedule | SK-08 | LO-08 | M07 | LAB-07 | A-08 | R-08 | grader log |
| Prove correctness | SK-09 | LO-09 | M08 | LAB-08 | A-09 | R-09 | grader log |
| Integrate M00–M08 | SK-01..09 | LO-01..09 | M08 close | LAB-A10 `mytool` | **A-10** | R-10 (12 checks, 3 critical) | grader log + written explanation (direct) |
| Operate a container stack | SK-10 | LO-10 | M09 L09.1–L09.3 | LAB-09a | CAP-01 | R-11.1–11.3 | live run transcript (direct, needs Docker) |
| IaC-style change | SK-11 | LO-11 | M09 L09.4–L09.6 | LAB-09b (mock + live) | CAP-01 | R-11.4–11.8 (critical: confirm-destroy, validate-before-mutate, idempotent) | mock test log (direct for logic) + live transcript |
| Diagnose/recover/hand over | SK-12 | LO-12 | M09 L09.7 | LAB-09c | **CAP-01R** | R-12 | fault report + runbook + recorded change |

Coverage check: every mandatory skill has instruction, graded practice, and an
independent assessment. **Gap flagged:** SK-10–12 evidence is *simulated* (mock)
until a Docker daemon is available to the learner and reviewer (V-04). No skill is
claimed from an assessment that does not exercise it (A-10 does not evidence SK-10–12).

---

## 4. Course map and prerequisite sequence

| Module | Authentic purpose | Prereq | Outcomes | Core concepts | Practice | Assessment | Indicative effort (planning aid, not a limit) |
|---|---|---|---|---|---|---|---|
| **M00** Orientation, environment, first script | Set up the container; write a usable script | none | LO-01 | shebang, execute bit, exit codes (and the `; echo "exit=$?"` proof idiom), printf, strict mode, shellcheck, `tar` | LAB-00 `greet` | D-01 (entry), A-01 | **1.75 h** |
| **M01** Variables & parameter expansion | Build names/values from inputs | M00 | LO-02 | quoting, `${}` forms incl. substrings, `read`, arithmetic, `export` / one-shot environment | LAB-01 | A-02 | 1.50 h |
| **M02** Conditionals & case | Guard input; route subcommands | M01 | LO-03 | `if`, `[[ ]]`, file tests, `case` | LAB-02 | A-03 | 1.25 h |
| **M03** Loops & arrays | Count things in data | M02 | LO-04 | `while read -r`, arrays, assoc arrays | LAB-03 | A-04 | 1.50 h |
| **M04** Functions & libraries | Structure for reuse/tests | M03 | LO-05 | `local`, status vs output, `source`, script-relative paths (`dirname "$0"`), Makefile recipe rules (reading) | LAB-04 | A-05 | 1.25 h |
| **M05** Text pipelines | Report from a log | M03 | LO-06 | grep (incl. context flags, `-E` vs `-P`)/awk/sort/uniq/sed/`tr -d '\r'`/`comm`, pipes, `<( )`, here-documents (quoted delimiter, `-`), `bash -n`, `jq`, `curl` status codes against a local server | LAB-05 | A-06 | 1.70 h |
| **M06** CLI & getopts | Make a tool others can rely on | M04 | LO-07 | positional params, `getopts`, stdin-or-file, exit codes, `${1:?}`/`:=` | LAB-06 | A-07 | 1.70 h |
| **M07** Robustness | Safe to schedule | M06 | LO-08 | `set -e` edges, traps, `mktemp`, `flock`, secrets hygiene (argv, environment, xtrace, file modes) | LAB-07 | A-08 | 1.55 h |
| **M08** Testing & quality | Prove it; keep it proven | M04 | LO-09 | assert harness, unit/black-box, shellcheck gate, `set -x`, wrapping Python | LAB-08 | A-09 | 1.35 h |
| **A-10** Integrative practical | Assemble a complete tool (`mytool`) | M00–M08 | LO-01..09 | — | LAB-A10 | **A-10** | 1.00 h |
| **M09** Infrastructure from Bash (IaC) | Provision/verify/destroy the program's fraud-clf stack | M06–M08 + Docker | LO-10..12 | compose lifecycle, config-as-data, validate→plan→apply, idempotency, locks, safe destroy, health checks, runbook | LAB-09a/b/c (`stackctl`) | **CAP-01**, **CAP-01R** | 3.50 h + 1.00 h assessment |
| Entry diagnostic D-01 | Route learners | — | — | — | — | D-01 | 0.25 h |

The course has **no fixed duration** (owner, 2026-10-26): learners stay on a module until its grader passes. The last column is the author's estimate of a typical entry-level learner's effort, used only to plan facilitated sittings and to size pilots; it is not printed on learner pages (which say *self-paced, no fixed duration*) and no module, lab or exercise has a time limit. The minute figures next to activities on module pages are pacing suggestions and say so (M00, *How this course works*).

**Prior-learning route.** D-01 (15 min) is a 10-item practical self-check (write and
run a script; quote a path with a space; explain `$?`). Learners who pass items 1–10
may skip M00–M02 and begin at M03 after running `bash grade-all.sh` to confirm
LAB-00..02 pass; failing D-01 does **not** make a beginner ineligible — it simply
routes them to M00.

---

## 5. Indicative effort by category (facilitator planning aid — not a budget, not a limit)

Author's estimate of a typical entry-level learner's effort by category, counted once per activity. Kept to size facilitated sittings and the pilot (V-05); superseded by measured times once V-05 reports. Nothing in the course is cut or capped to fit these figures:

| Category | Hours | Where |
|---|---|---|
| Orientation & setup | 0.75 | M00 S00.1–S00.3 |
| Instruction (concept steps) | 4.60 | M00 0.35 · M01 0.40 · M02 0.35 · M03 0.40 · M04 0.35 · M05 0.55 · M06 0.55 · M07 0.45 · M08 0.45 · M09 0.75 |
| Demonstration (worked `lab.sh` walkthrough) | 1.35 | M00–M08 × 0.15 |
| Guided practice (exercises with grader) | 9.45 | M00 0.50 · M01 0.95 · M02 0.75 · M03 0.95 · M04 0.75 · M05 0.95 · M06 0.95 · M07 0.90 · M08 0.75 · M09 2.00 |
| Independent practice (transfer task + reading the program's scripts) | 0.90 | M09 L09.7 0.75 · "Read the real thing" M05/M06/M07 0.15 (M08's reading sits inside its concept time) |
| Summative assessment | 2.25 | D-01 0.25 · A-10 1.00 · CAP-01 1.00 |
| Recovery / remediation | 0.70 | course-level, mostly Docker installation |

Module totals are the sums of their categories (e.g., M05 = 0.55 + 0.15 + 0.95 + 0.05 = 1.70 h; M09 = 0.75 + 2.00 + 0.75 = 3.50 h) and the categories sum to roughly 20 h of indicative effort — the figure the course was originally parameterized to, now retained only as a planning estimate. **Practical share:** guided + independent ≈ 10.35 h, about half of the indicative effort, or about 62 % counting A-10 and CAP-01 as hands-on. A-01…A-09 take no separate time: they are the completion evidence of each guided exercise. These estimates are **design assumptions until a pilot** measures them; trainer preparation time (rehearsal, grading) is budgeted separately in the Trainer Edition. The first `up` in CAP-01 (image build) is untimed. **Batch 6 (2026-10-25)** added S05.6 `jq`, S06.6 required inputs, S08.5 wrapping Python and four "read the real thing" exercises; **2026-10-26** the fixed 20-hour duration was removed at the owner's instruction, so later additions are judged on whether Course 1–3 need them, not on whether they fit.

---

## 6. Assessment plan

| ID | Skills | Scenario/conditions | Allowed resources | Deliverables | Acceptance | Threshold / critical gates | Evidence | Reassessment |
|---|---|---|---|---|---|---|---|---|
| D-01 | SK-01..03 | 15-min self-check in the container | none | 10 short tasks | self-scored | routing only | self-check | n/a |
| A-01…A-09 | SK-01…09 | each module's exercise | lesson + any docs; AI disclosed | `work/` files | grader `0 failed` + 2 reflection answers | pass/fail | grader output | re-run grader after fixing |
| **A-10** | SK-01..09 | assemble `mytool` to the rubric (1 h) | lesson pages; no solution/ | `work/mytool` + 150-word decisions note | 12 checks, R-10 | ≥80% weighted; **critical:** exit codes 0/1/2 correct, shellcheck clean, trap present | grader log + note | A-10R: same rubric, different subcommand names and exit-code map |
| **CAP-01** | SK-10..12 | operate `stackctl` on the fraud-clf baseline for env test then prod (live, transcribed); run tests; produce runbook with inherited findings (1 h assessed) | docs; AI disclosed | `stackctl`, `envs/*.conf`, tests, `RUNBOOK.md`, `MANIFEST.txt`, run transcript | R-11 (8 criteria) | ≥80%; **critical:** validate precedes mutation; plan never mutates; `up` re-run converges; destroy refuses without `CONFIRM_DESTROY=<env>`; no global prune; no fabricated digest; no secrets; `app/` untouched | transcript + files | **CAP-01R**: ports 28080/28081, projects `fraudclf-r-*`, one injected fault (F1–F9) |
| **CAP-01R** | SK-12 (+10,11) | change request + fault diagnosis under observation (recorded terminal or live) | docs | fault report, fixed stack, explanation | R-12 | critical: fault located and explained; fix verified by `check` | recording/transcript | equivalent variant with a different fault |

**Rubric framework.** Each criterion has three observable levels — *Not met / Met /
Strong* — with criterion-specific descriptors (defined per module in the Trainer
Edition). Score = Σ(criterion weight × level/2); threshold 80%; any *critical*
criterion at *Not met* fails the assessment regardless of total. No speed, polish,
or memorized-syntax grading.

**AI-use policy.** Practice: any assistance, disclosed in the reflection. A-10/CAP-01:
AI permitted for documentation lookup; the written decisions note and CAP-01R's live
change establish independent capability. The course makes **no claim of AI detection**.

**Evidence boundary (self-paced).** Grader results are *self-check mastery*.
*Independently verified mastery* requires a reviewer (human or configured automation)
to inspect A-10/CAP-01 evidence and observe CAP-01R; the owner decides whether to
staff this. Without it, completion certificates should say "self-assessed."

---

## 7. Capstone contract — `stackctl` (M09, CAP-01)

A Bash tool that operates the SecMLOps program's own project, **fraud-clf**
(`secmlops-project-baseline`, tag `m0` — the service Course 2 takes to production),
on the learner's laptop: `serve` (the baseline's FastAPI model API, built locally from
the inherited repo copy with a course-supplied `Dockerfile.course` that trains the
model at build time) behind `gateway` (a pinned nginx image, the only published
port), in two environments.

| Element | Contract |
|---|---|
| Environments | `test` (port 18080, project `fraudclf-test`) and `prod` (18081, `fraudclf-prod`) — Course 2's test/production pair; separate `envs/test.conf`, `envs/prod.conf` |
| Config as data | `KEY=VALUE` files **parsed**, never `source`d; whitelist of keys (PORT, PROJECT, APP_DIR, IMAGE_SERVE, IMAGE_GATEWAY, HEALTH_PATH, HEALTH_BODY, WAIT_TIMEOUT) |
| The app | `app/` is the baseline **unmodified** plus `Dockerfile.course`; its planted weaknesses (example S3 keys, `requests==2.19.1`, unauthenticated `/api/predict`, root image) are kept on purpose and listed by the learner in the runbook's *Inherited findings* — a modified `app/` is a critical failure (it is Course 2's work) |
| Commands | `help` · `validate` · `plan` · `up` · `check` · `status` · `logs` · `destroy` |
| validate | parse config; required keys; PORT numeric 1024–65535; `APP_DIR/Dockerfile.course` exists; `HEALTH_PATH` starts with `/`; `docker compose config` renders (client-side, works without a daemon); **no mutation** |
| plan | shows desired vs applied (last render) vs running (`compose ps`) and states plainly what `up` would change; **must not create/delete anything** and must describe its limits (it cannot predict the build, pulls or health) |
| up | `docker compose --project-name "$PROJECT" up -d --wait --wait-timeout "$WAIT_TIMEOUT"` (S-02); builds `serve` when the image is missing; re-running converges with no changes; validate runs first |
| check | `curl -fsS http://127.0.0.1:$PORT$HEALTH_PATH` through the gateway must equal `HEALTH_BODY` (`{"status":"ok"}`, the app's exact bytes) **exactly**; exit 3 on mismatch, 1 if unreachable |
| status / logs | `compose ps` / `compose logs --tail` scoped to the project |
| destroy | refuses unless `CONFIRM_DESTROY` equals the selected env; `compose down -v` **scoped to the project**; **never** `docker system prune` |
| Isolation & locking | `flock -n envs/<env>.lock` around up/destroy; two envs never share names/ports |
| Exit codes | 0 ok · 1 runtime · 2 usage/validation · 3 check failed |
| Robustness | `set -euo pipefail`; code-preserving trap; `mktemp` for rendered files |
| Images | gateway pinned by tag **and** a digest **recorded by the learner** from `docker image inspect`; serve is a local build with **no** registry digest — its image ID is recorded the same way; a digest or ID copied from a document is a critical failure |
| Tests | `tests/` with a mock driver (`STACKCTL_DRIVER=mock`) proving control logic without a daemon (34 cases), plus `tests/live-smoke.sh` requiring a daemon (includes one prediction call); negative cases (bad PORT, missing key, missing Dockerfile.course, bad HEALTH_PATH, destroy without confirm) |
| Handover | `RUNBOOK.md` (what it is, operate, diagnose, recover, versions and digests, **inherited findings** with their Course 2 milestones) and `MANIFEST.txt` (tool versions, gateway digest, serve image ID, date) |
| CAP-01R | ports 28080/28081, projects `fraudclf-r-*`; one injected fault (nine catalogued, F1–F9: non-numeric PORT, missing key, body with a space, wrong HEALTH_PATH, shared PROJECT, wrong gateway upstream port, held lock, gateway tag typo, missing Dockerfile.course) the learner must locate, explain and fix under observation |

**Program hand-off:** a CAP-01 pass is Course 2 Module 0 ("run the finished thing")
done early; the runbook's *Inherited findings* list is the baseline README's "list
everything that worries you", handed to the Course 2 instructor.

**Evidence boundary:** the mock driver validates *decision logic* only. A dry run,
rendered plan, or mock transcript is **not** evidence of provisioning; CAP-01 requires
a live transcript from a machine with a daemon (V-04).

---

## 8. Environment specification (summary; details in `env/README.md`)

Learner machine (the program's host-OS list): Ubuntu/Debian 22.04+ (Docker Engine +
Compose plugin from Docker's apt repository), macOS Intel/Apple Silicon (Docker
Desktop), or Windows 11 inside WSL 2 Ubuntu (Engine in the distro, or Docker Desktop
with WSL integration); a learner who finished Course 1 may run everything in its lab VM.
No PowerShell twins: the shell is the subject, so Windows learners use the Ubuntu shell. Course image `bash-course:2.0` built locally from `env/Dockerfile`
(Ubuntu 24.04 base; bash 5.x, coreutils, awk/sed/grep, util-linux, shellcheck, jq,
curl, git, python3, make — the last two added in Batch 7, python3 having been missing
since Batch 6's S08.5; non-root `learner`). M00–M08 run inside the container with the bundle
bind-mounted at `/course`; M09 runs on the host shell and builds one image locally
(`fraudclf-serve:m0`, from the baseline's `requirements.txt` — network needed once). Fallback for M00–M08: any
bash ≥ 4 + shellcheck (+ jq, curl, python3, make for the steps that name them). macOS
hosts install bash 5, `flock` and the GNU tools through Homebrew with the same `PATH` line
Course 2 prescribes (env/README §3 step 6, Batch 7) so M09/CAP-01 run as written there. **Status:** image definition designed; not built in the
authoring environment (no daemon) → V-01.

---

## 9. Evidence and source register

| ID | Source | Used for | Status / access |
|---|---|---|---|
| S-01 | Course bundle v1 (`bash-course.zip`, labs, exercises, `logsleuth`) | all M00–M08 content, graders, expected outputs | **Executed** in the authoring environment (bash 5.2.21, shellcheck 0.11.0): 10 walkthroughs 194 checks + 10 exercise solutions 68 checks + 17 project tests, 0 failed (2026-10-16, re-run 2026-10-18 and 2026-10-21) |
| S-02 | Docker Docs — "docker compose up" CLI reference, https://docs.docker.com/reference/cli/docker/compose/up/ | `--wait` ("Wait for services to be running\|healthy. Implies detached mode."), `--wait-timeout` ("Maximum duration in seconds to wait…"), `--remove-orphans`, `-d` | **Accessed 2026-10-18** |
| S-03 | GNU Bash Reference Manual (gnu.org) | `set -e` exceptions, `trap`, parameter expansion, `getopts`, `read` | Behaviors **observed empirically** in S-01 runs; manual text **not re-accessed** this batch → V-03 |
| S-04 | ShellCheck wiki SC2086, SC2154 | lint findings taught in M00/M07 | Findings **observed** (shellcheck 0.11.0); wiki pages not fetched → V-03 |
| S-05 | Docker Desktop / Engine install docs; Docker Desktop licensing terms | M00 setup, cost note | **Not accessed** → V-02 (install steps are pointers, not reproduced claims) |
| S-06 | Docker Hub `nginx` official image, `python:3.12-slim` base, and the program's `secmlops-project-baseline` (tag m0) | M09 image choice; `app/` copy | Baseline read from the program's own tarball; registry images not accessed; digests must be **recorded at pull time** by the learner, never copied |

No employer, labor-market, or certification claims are made. Instructional wording
and examples are original.

---

## 10a. What Course 0 produces — the contract with Courses 1, 2 and 3

The program's rule: a later course never installs or configures something an earlier
one should have produced. Course 0's outputs and where they are consumed:

| Course 0 output | Where it is made | Consumed by |
|---|---|---|
| Reading and writing bash to the program's standard: strict mode, quoting, `getopts` + `case`, exit codes as an API, traps, parsed config, a test harness, shellcheck-clean | M00–M08, A-10 | every `ci/*.sh` stage and `scripts/*.sh` in Course 2; Course 1's `Makefile` targets and `scripts/` (`ready-check.sh`, `smoke.sh`, `tools-check.sh`, `replica-check.sh`); Course 3's `dev` scripts |
| Docker Engine/Desktop working on the laptop (`docker compose version`) | M00 S00.1 | Course 2 Lab 7.1 (the one local image build); Course 1 does not need it on the laptop (Docker lives on the lab VM) |
| `logsleuth` — the learner's log analyzer over the fraud-clf gateway log and the lab VM sshd log | M01–M08 | not required by any later course; a ready tool for reading the gateway and sshd logs the Course 2 lab produces (Chapter 11's nightly validation runs) |
| `stackctl` + a live, transcribed run of the **fraud-clf baseline** (`test` and `prod`), a `MANIFEST.txt` with recorded gateway digest and serve image ID, a runbook whose §6 lists the baseline's inherited findings | M09, CAP-01 | **Course 2 Module 0** ("run the finished thing") is already done; the §6 list is the baseline README's "everything that worries you" and seeds Milestones 2, 4, 6, 7 and 10; the validate → plan → apply, lock and named-confirmation habits are the ones Course 1 Modules 3, 5 and 9 assume |
| The habit of labeling outputs *observed* vs *designed* and never copying a digest | all modules | Course 2 Milestones 8 and 14 (`image.digest`, same-digest promotion) |

If a later course's check fails on one of these, the fix is in the Course 0 module
named here — never in the later course.

---

## 10. Edition packaging plan

| Package | Contents | Must NOT contain |
|---|---|---|
| **Student Edition** (`student/`) | module pages M00–M09, D-01, A-10 and CAP-01 task specs + learner-visible rubrics, `labs/*/exercise/{TASK.md,starter/,grade.sh}` (starter includes the fraud-clf `app/` copy), `labs/_exercise.sh`, `grade-all.sh`, `seed/`, `logsleuth/` (the reference tool is **course material**, not a protected answer), `env/` | `labs/*/exercise/solution/`, `labs/*/lab.sh` walkthroughs for A-10/CAP-01 scopes, trainer rubrics with descriptors, CAP-01R fault list |
| **Full Trainer Edition** (`trainer/`) | every student page reproduced verbatim + TRAINER ONLY blocks, all `solution/` dirs, `lab.sh` walkthroughs, scoring procedures, calibration examples, CAP-01R faults and solutions, rehearsal/prep, `prove_all.sh` | — |

Formative answers (per-step expected output, hints) are allowed in the Student
Edition. Chat labels and filenames are not access control; leakage check (filenames,
archives, metadata) is a release gate.

**Platform editions.** Each edition is also produced per operating system (Ubuntu/Debian, macOS, Windows 11 via WSL 2 Ubuntu) by `tools/build_os.py` from the all-platform master: marker blocks in `env/README.md` select the install sections; `tools/os-variants.json` holds the exact-text variants for M00, M01, M03, M09, CAP-01 and the trainer callouts; macOS additionally rewrites every host-side `sed -i` to the BSD form. `tools/package-all.sh` builds the master plus the three editions (eight archives) and runs the leakage check on each student archive. The master is the only thing edited; a variant that no longer matches fails the build.

---

## 11. Maintenance plan

- **Version** 2.0.0-draft (this blueprint, 2026-10-18; revised 2026-10-21). Semantics: major = outcome/
  assessment change; minor = compatible additions; patch = corrections.
- **Owner:** proposed — course owner. **Cadence:** quarterly + triggers: Docker Engine/
  Compose releases that change `up --wait` behavior; Ubuntu base-image changes;
  ShellCheck rule changes; bash minor versions; repeated grader failures; learner
  reports of install problems; accessibility barriers; **a new tag of `secmlops-project-baseline`** (re-copy `app/`, re-run the lab9 grader and suite, re-check `leakcheck.sh`'s planted-key assertion).
- **Dependency register:** Docker Engine/Compose (M09, CAP-01, env) · `ubuntu:24.04`
  base (env) · shellcheck (M00, M07, M08, gates) · bash ≥ 4 / macOS 3.2 note (all) ·
  `nginx:1.27-alpine` / `python:3.12-slim` tags, the baseline's `requirements.txt` (unpinned scikit-learn/pandas) and the busybox `wget` healthcheck in
  `compose/stack.yml.tmpl` (M09) · util-linux `flock` (M07, M09; Linux/container only) · Course 1/2 file names cited in the "In the SecMLOps Program" sections (`ci/*.sh`, `scripts/*.sh`, `Makefile` targets) — re-check when those courses change.
- **Workflow:** detect → impact map (IDs above) → propose → revise both editions →
  `prove_all.sh` + mock tests + V-04 live smoke → review → release → monitor.
- **Metrics (collection to be configured):** per-criterion mastery, grader first-pass
  rate per lab, time-on-module (self-report), CAP-01R fault-location rate, learner
  feedback. No baselines or targets are asserted. Monitoring is **not** configured by
  this document.

---

## 12. Quality gates — final status (Batch 5, 2026-10-21)

| Gate | Status | Evidence / remaining action |
|---|---|---|
| Request/mode/scope fidelity | Pass | FULL COURSE delivered in four batches + program integration; parameters honored (§1.1); two Notion trees, one per edition |
| Evidence & citation integrity | Partial | S-01 executed, S-02 accessed; S-03–S-06 remain verification tasks (V-02, V-03); no citation fabricated; every output labeled observed/designed |
| Observable outcomes & traceability | Pass (design) | §2–§3; SK-10–12 evidence simulated (mock) until V-04 |
| Prerequisite order & beginner feasibility | Pass (design) | §4; D-01 routing; pilot pending (V-05) |
| Reconciled workload | Pass (as a planning aid) | No fixed duration (owner, 2026-10-26); §5 indicative effort ≈ 20 h is internally consistent with §4 and the module pages carry no budgets |
| Lesson/step completeness | Pass | M00–M09 (64 steps after Batches 6–7), A-10, CAP-01/CAP-01R, D-01; every step has the full contract; every module has an "In the SecMLOps Program" bridge |
| Assets/env feasibility/verification | Partial | pure-bash and mock-driver assets executed (`prove_all.sh` ALL GREEN: 11 walkthroughs, 11 graders, 17 project tests, shellcheck clean); image build and live Docker paths designed → V-01, V-04 |
| Assessments/rubrics/reassessment | Pass | R-01…R-12 with Met/Strong/Not-met descriptors; A-10R kit executed; CAP-01R fault list F1–F9 (F1, F2, F3, F6, F9 and the F4/F5/F8 tells observed with the mock driver; F4/F5 live effects and F7 designed) with equivalence rule |
| Trainer content & solutions | Pass | trainer pages for every module and assessment; solutions for LAB-00…LAB-09 and A-10 executed |
| Edition parity & separation | Pass | mechanical merge + parity diff (PARITY OK for M01–M09, A-10, CAP-01; M00 hand-merged and spot-checked); `tools/leakcheck.sh` PASS on the student archive (incl. the inherited-app assertions) |
| Accessibility/support realism/cost | Partial | text-only materials; no paid services; help route unconfigured (A3); macOS `flock`/`sed -i` caveats documented in M09; WSL 2 route documented, not observed |
| Versioning/dependencies | Pass | §11; nginx/python tags, the baseline's requirements and the busybox `wget` healthcheck and the cited Course 1/2 file names added to the dependency register |
| Technical validation performed | Partial | everything that runs without a daemon executed; Docker-dependent outputs designed |
| Independent review / pilot | Not assessed | none yet; required before "validated" |
| Scope completion | Pass | Batch 4 of 4 + Batch 5 (program integration: Course 0 position, platforms, fraud-clf project, bridges) |

**Release blocker for "ready for pilot":** V-01 (build/run image), V-02 (install
pointers checked), V-04 (one live run of the reference `stackctl` by the trainer).
**Blocker for "validated release":** V-04 learner evidence and a learner pilot (V-05).

## 13. Verification tasks (status at release)

- **V-01** Build `bash-course:2.0`; run `tools-check.sh` and `prove_all.sh` inside it; record digests/versions. — **open**
- **V-02** Check current Docker Desktop/Engine install docs and licensing terms; record access dates. — **open**
- **V-03** Attach GNU Bash manual and ShellCheck wiki citations (with access dates) to the specific claims in M00/M07/M08. — **open**
- **V-04** On a daemon-equipped machine, run `labs/lab9-stackctl/exercise/solution/tests/live-smoke.sh` for `test` and `prod` (first `up` builds the fraud-clf image; needs network) and `tools/record-manifest.sh`; then CAP-01 and CAP-01R with a learner; attach transcripts. — **open** (a Docker client and Compose v5.5.1 were present in the authoring environment, so `validate` was observed with the real driver; `up`/`down`/`ps`/`logs` were not)
- **V-05** Learner pilot: time-on-module, first-pass grader rates, CAP-01R fault-location rate. — **open**
