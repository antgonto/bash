# M00 — Orientation, your environment, and your first script
**FULL TRAINER EDITION · curriculum v2.0.0-draft · self-paced, no fixed duration**

> **TRAINER ONLY — about this edition.** Every student-facing line of M00 is
> reproduced below unchanged; trainer material appears in blocks like this one at the
> point where it applies. You can teach, support, and grade from this document alone.
> Component IDs (S00.x, LAB-00, A-01, D-01) are shared with the Student Edition.
>
> **Before you support anyone (prep ≈ 45 min, once per cohort):**
> 1. Perform **V-01** (see `env/README.md`): build `bash-course:2.0`, then inside it run
>    `bash tools-check.sh` (expect `ready`) and `bash prove_all.sh` (expect `ALL GREEN`).
>    Record the base-image digest and tool versions in `env/MANIFEST.txt`. Until V-01
>    passes on your machine, tell learners the container path is "pilot," not "validated."
> 2. Rehearse LAB-00 as a learner: `cd labs/lab0-first-script/exercise && rm -rf work &&
>    bash grade.sh` → **observed** `---- lab0: 2 passed, 4 failed ----`; then grade the
>    reference: `GRADE_TARGET="$PWD/solution" bash grade.sh` → **observed**
>    `---- lab0: 6 passed, 0 failed ----` (authoring env, 2026-10-16). If your counts
>    differ, stop and investigate before releasing the module.
> 3. Confirm the help route you will actually staff (forum/email/office hours) and write
>    it into the student page's "Getting help" line. **None is pre-configured.**
> 4. Decide the AI-use wording you will enforce (default in §1.3 of the blueprint).
>
> **Trainer effort estimate (not learner time):** prep 45 min; A-01 review ≈ 5 min per
> learner (grader is automatic; the two reflections need a human read).
>
> **Facilitator pathway (optional 60-min live session for blended use).**
> 0–10 min: show S00.4 live — type `greet` from an empty file, run both ways.
> 10–25 min: learners do S00.4–S00.7 at their own pace; you circulate on S00.1–S00.3
> install trouble (see per-step notes). 25–35 min: S00.8–S00.9 together; make the
> SC2086 demonstration the centerpiece. 35–55 min: LAB-00 individually. 55–60 min:
> debrief R1/R2 aloud (expected answers under LAB-00 below).

**Outcome LO-01.** You can create a script from an empty file, run it two ways, give it
exact output and an argument, harden it with the strict-mode header, read its exit
code, lint it clean, and install it as a command — and you can explain each choice.

**What you'll have at the end.** A working command, `greet`, on your PATH; the course
environment running; your first graded exercise green (A-01).

**Where this course sits.** This is **Course 0** of the SecMLOps program — the
shell foundation that Courses 1, 2 and 3 assume. Its project, `logsleuth`, analyzes
the logs of the program's own fraud-detection API; its capstone, `stackctl`, runs
that API on your laptop the way Course 2 later runs it on a cluster. Nothing here
requires the other courses; everything here is used by them.

---

## How this course works (read once — 5 min)

- **One project, ten modules.** You learn bash by building pieces of a real
  log-analysis tool, `logsleuth`, over the logs of the program's fraud-clf API and
  lab server, and in M09 you transfer those skills to `stackctl`, which builds,
  provisions, verifies and tears down that very API as containerized
  infrastructure.
- **Every module = lesson → worked demo → your exercise.** The lesson is a numbered
  build (edit → run → read the exact output → why). The worked demo
  (`labs/<lab>/lab.sh`) replays the same moves and self-grades, so you can watch it.
  The exercise (`labs/<lab>/exercise/`) is *yours*: a starter file with `# TODO`
  lines, and a grader that checks *your* work.
- **No clock.** The course has no fixed duration and no module has a time limit. The
  minute figures next to some activities (`10 min`, `30 min`) are pacing suggestions
  so you can plan a sitting; they are not a target and never a deadline. Stay on a
  module until its grader passes and you can explain *why* it passes.
- **Graders tell the truth.** `bash grade.sh` prints one `PASS:`/`FAIL:` per check and a
  summary like `---- lab0: 6 passed, 0 failed ----`. `0 failed` is the goal; a FAIL
  tells you what was expected versus what happened.
- **Self-check answers are in each module's last section**, after the exercise. Try
  first, then check.
- **Getting help.** Self-paced. *Help route: to be configured by your course owner*
  (for example an LMS forum). The Recovery line under every step is written for a
  beginner working alone.
- **Prerequisites.** None beyond using a computer, creating folders and files, and
  typing in a terminal. You need admin rights to install Docker (Step S00.1).
- **AI tools.** You may use them while practicing; say so in your reflection. Graded
  tasks later in the course also ask you to explain your decisions in your own words.

> **TRAINER ONLY.** The two things beginners most often misunderstand here: (a) they
> think `lab.sh` *is* their exercise — it is the worked answer; their work lives in
> `exercise/work/`; (b) they treat a FAIL as a verdict rather than as the next
> instruction. Say both explicitly in your first message to the cohort.

---

## D-01 — Entry self-check (15 min, optional routing)

If you have scripted before, try these without looking anything up. If all ten are
easy, run `bash grade-all.sh` after setup: when LAB-00…LAB-02 pass, start at M03.
If any item is unfamiliar, start here at M00 — that is the intended path.

1. Create a file whose first line names the interpreter. 2. Make it executable and
run it with `./`. 3. Print `Hello, World!` with `printf`. 4. Use the first argument
with a default. 5. State what `$?` holds after a command. 6. Quote a variable holding a
path with a space so it stays one argument. 7. Name the three parts of
`set -euo pipefail`. 8. Explain what `A && B` and `A || B` do. 9. Run `shellcheck` on a
script. 10. Copy a script onto your PATH and run it by name.

(Answers for self-scoring: §"Self-check answers" at the end.)

> **TRAINER ONLY — D-01 is routing, not gating.** Its only use is to let experienced
> learners skip to M03 *after their graders for LAB-00…02 pass* (that is the real
> evidence, not the self-check). Never use D-01 to exclude a beginner. If a learner
> passes D-01 but fails LAB-01's grader, route them back to M01 — a common pattern for
> people who have copied scripts without writing them.

---

## Activity context for S00.1–S00.3 (environment)

| Field | Value |
|---|---|
| Execution context | **Your computer's own terminal**, in the unzipped course folder. Supported platforms, the same as the rest of the program: **Ubuntu/Debian** (22.04 or later; any terminal), **macOS** (Intel or Apple Silicon; Terminal or iTerm), **Windows 11** — *inside WSL 2 Ubuntu*: every command in this course is typed in the Ubuntu terminal that WSL gives you, never in PowerShell. (Windows 11 support added 2026-10-21; before that the course was published for **macOS** and **Ubuntu**.) |
| Starting state | Course bundle unzipped; you can open a terminal in that folder |
| Permissions | Administrator/sudo rights for Step S00.1 only |
| Cost | No paid service required; see Docker Desktop licensing note in `env/README.md` |
| Validation status | Steps S00.1–S00.3 are **designed, not executed** by the course authors (no Docker daemon in the authoring environment). Expected observations below are illustrative; verification task V-01 is open. |

> **TRAINER ONLY — expect setup to be where learners lose the most time.** The course
> has no fixed duration (owner, 2026-10-26), but the blueprint's §5 planning aid still
> expects Docker installation to be the single largest source of lost time, as in
> pilots of comparable courses (an authoring expectation, not measured data for this
> course — record actual times in V-05). Triage order:
> 1) daemon not running (most common) → start Desktop / `systemctl start docker`;
> 2) Ubuntu socket permission → `docker` group + re-login; 3) Ubuntu with the distro
> `docker.io` package or the v1 `docker-compose` binary → no `docker compose` subcommand,
> reinstall from Docker's apt repository; 3b) Windows 11: virtualization off in UEFI or
> `wsl --update` needed; course folder under `/mnt/c` (slow, loses the execute bit and LF
> endings) → move it to `~`; Docker Desktop's WSL integration not enabled for the Ubuntu
> distro; 4) corporate proxy/VPN blocking pulls → fallback
> path for M00–M08 and defer Docker to M09. Do not let a learner burn more than ~30 min
> before switching to the fallback; the fundamentals do not need Docker.

### S00.1 — Install Docker (once)
- **Purpose.** The course runs inside a container so your tools match everyone's; later, scripts you write will *manage* containers.
- **Exact action.** 1) **Windows 11 only, first:** in an administrator PowerShell run `wsl --install -d Ubuntu`, reboot, open the *Ubuntu* app and create your Linux user; from here on you are on Ubuntu, and the course folder must live under your Linux home (`~/`), not under `/mnt/c/…`. 2) Install Docker. **macOS:** Docker Desktop (Intel or Apple Silicon build). **Ubuntu/Debian, and WSL 2 Ubuntu:** Docker Engine and the Compose plugin from Docker's apt repository (the `docker-ce`, `docker-ce-cli`, `containerd.io` and `docker-compose-plugin` packages); on Windows 11 you may instead install Docker Desktop for Windows and enable its *WSL 2 integration* for the Ubuntu distro — either way `docker` is run from the Ubuntu terminal. Follow the current official installation page for your OS (`docs.docker.com`); the full step-by-step commands for each OS — adding Docker's apt repository, the `docker` group, enabling systemd in WSL 2, and the Docker Desktop alternative — are on the **Environment (Docker) — setup, step by step** page (`env/README.md`, sections 2–4); do that page first if Docker is not installed yet. 3) Start Docker (the Desktop app on macOS or Windows; `sudo systemctl start docker` on Ubuntu — inside WSL 2, `sudo service docker start` if `systemctl` is not available). 4) Run:
  ```bash
  docker version
  docker compose version
  ```
- **Inputs.** None.
- **Expected observation (illustrative).** `docker version` prints a **Client** section *and* a **Server** section; `docker compose version` prints `Docker Compose version v2.x` or newer.
- **Verification.** Both sections present → proceed. Only *Client* shown → the daemon is not running.
- **Recovery.** *Server missing on macOS:* start Docker Desktop and wait for "Engine running". *Server missing on Ubuntu:* `sudo systemctl start docker`; `permission denied while trying to connect to the Docker daemon socket` → `sudo usermod -aG docker "$USER"`, then log out and back in. *`docker compose` unknown on Ubuntu* → the `docker-compose-plugin` package is missing (the old `docker-compose` v1 binary and the `docker.io` distro package are not what this course uses). *WSL 2:* `wsl --install` fails or Ubuntu will not start → virtualization is disabled in the BIOS/UEFI, or `wsl --update` is needed first; Docker Desktop's WSL integration toggle is under *Settings → Resources → WSL integration*. `bad interpreter` or `^M` errors in a file you edited from Windows → the editor saved CRLF line endings; set it to LF (VS Code: the `CRLF`/`LF` switch in the status bar). *Going on to Course 1 on Windows 11:* WSL 2 needs the Hyper-V hypervisor, and Course 1 Module 0 asks you to turn it off (`bcdedit /set hypervisorlaunchtype off`) for a faster VirtualBox — do that only after Course 0, and turn it back on (`… auto`) when you need WSL 2 again; or keep Hyper-V on and accept a slower lab VM; or run Course 0 inside the Course 1 lab VM, which has no such conflict. If still blocked after 30 min, use the **fallback** in `env/README.md` §8 for M00–M08 and return to Docker before M09.
- **Evidence / next state.** Both version outputs saved in `notes/M00-setup.txt` (any text file). Docker running. **Already did Course 1?** Its Ubuntu lab VM has Docker; `vagrant ssh lab`, clone the course folder there, and do everything in this course inside the VM instead.

> **TRAINER ONLY.** The install commands live on the Environment page so they can be
> re-checked once per cohort (V-02: re-verify them against Docker's site and note the
> access date). Until 2026-10-21 they were deliberately *pointed to*, not reproduced:
> they change, and a stale copy is worse than none — which is why V-02 exists. What to observe in a learner's
> `docker version`: a Server block. Teaching line: "The Client is the `docker`
> command; the Server is the engine that actually runs containers — if only the
> Client answers, nothing can run yet."

### S00.2 — Build the course image (once)
- **Purpose.** Produce the shared tool image `bash-course:2.0` from the course's Dockerfile, and record what you actually got.
- **Exact action.** In the course folder:
  ```bash
  docker build -t bash-course:2.0 env/
  docker image inspect --format '{{index .RepoDigests 0}}' ubuntu:24.04 | tee -a env/MANIFEST.txt
  docker run --rm bash-course:2.0 bash -c 'bash --version | head -1; shellcheck --version | sed -n 2p; jq --version' | tee -a env/MANIFEST.txt
  ```
- **Inputs.** None (the Dockerfile is provided).
- **Expected observation (illustrative).** The build ends with a line naming the image; `MANIFEST.txt` gains a `ubuntu@sha256:…` line (yours — do not copy one from anywhere) and three version lines.
- **Verification.** `docker image ls bash-course` lists `bash-course 2.0`.
- **Recovery.** *Network/pull errors:* retry once connected. *"permission denied" on the socket (Linux):* see S00.1 recovery. *Build fails on `apt-get`:* retry (mirror hiccup); if it persists, the base-image tag may have moved — report it; use the fallback meanwhile.
- **Evidence / next state.** `env/MANIFEST.txt` with your recorded digest and versions. Image present.

> **TRAINER ONLY — why the manifest matters pedagogically.** This is the first time the
> course asks learners to *record a real identifier rather than copy one*. It
> foreshadows M09's rule that a digest copied from a document is a critical failure.
> Check one learner's `MANIFEST.txt` publicly: the digest will differ from yours if the
> base tag moved — a perfect, concrete lesson in why tags are not pins.

### S00.3 — Start a lab session and run the preflight
- **Purpose.** Enter the container with the course folder mounted, and confirm the tools are present.
- **Exact action.**
  ```bash
  docker run --rm -it -v "$PWD":/course -w /course bash-course:2.0
  bash tools-check.sh
  ```
- **Inputs.** `$PWD` is the course folder (or use the full path).
- **Expected observation (illustrative for the container; the script's output is observed in S-01).** A prompt such as `learner@…:/course$`, then `tools-check.sh` ending with `ready: N tools present`.
- **Verification.** `ready` appears; `bash --version` shows 5.x.
- **Recovery.** *Prompt appears but `/course` is empty:* you started outside the course folder — `exit` and re-run from the right folder. *"invalid reference format"*: a typo in the image name. *Fallback (no Docker):* open your own bash ≥ 4 shell in the course folder and run `bash tools-check.sh` — it reports exactly what is missing.
- **Evidence / next state.** You are inside the container (or fallback shell) at the course root. **Type `exit` to leave at any time; your files stay on your computer.**

> **TRAINER ONLY.** The bind mount (`-v "$PWD":/course`) is the single most important
> idea in this step: *the container is a toolbox, the files are theirs*. Learners who
> miss this fear that `exit` deletes their work. Demonstrate: create a file inside the
> container, `exit`, show it in the host folder. On macOS with bash 3.2 as the host
> shell, insist on the container (or `brew install bash`) — associative arrays in M03
> will not work on 3.2.

---

## Activity context for S00.4–S00.11 (your first script)

| Field | Value |
|---|---|
| Execution context | Inside the container (or fallback shell), **working directory** `~/bash-course-work/lab0`, created in S00.4 |
| Starting state | S00.3 complete (`tools-check.sh` says ready) |
| Tools | `bash`, a text editor (`nano` is in the image: `nano greet`, save with Ctrl+O, Enter, exit with Ctrl+X), `shellcheck` |
| Validation status | All expected outputs in S00.4–S00.11 were **observed** in the authoring environment (bash 5.2.21, shellcheck 0.11.0, GNU tar 1.35; 2026-10-16, S00.11 on 2026-10-26) |

The loop for every step is the same: **edit the file → run it → read the exact output
→ understand why.** Type the scripts yourself; that is the point.

### S00.4 — A file, a shebang, and the execute bit
- **Purpose.** A script is a plain text file whose first line (the **shebang**) names the interpreter. You learn the two ways to run one. (SK-01)
- **Exact action.** 1) `mkdir -p ~/bash-course-work/lab0 && cd ~/bash-course-work/lab0`. 2) Create a file named `greet` containing exactly:
  ```bash
  #!/usr/bin/env bash
  echo "hello"
  ```
  3) Run it two ways:
  ```bash
  bash greet
  chmod +x greet
  ./greet
  ```
- **Inputs.** None.
- **Expected observation (observed).** Each run prints `hello`.
- **Verification.** Two lines of `hello`, no errors.
- **Recovery.** `bash: ./greet: Permission denied` → you skipped `chmod +x greet`. `No such file or directory` → you are in the wrong directory (`pwd`), or the file name differs (`ls`). `bad interpreter` → the first line is not exactly `#!/usr/bin/env bash` (check for a leading space or CRLF line endings from an editor set to Windows mode: `cat -A greet` shows `^M` at line ends; recreate the file in the container's editor).
- **Evidence / next state.** `greet` exists and runs. **Why:** `#!/usr/bin/env bash` finds `bash` on your PATH (portable across Linux/macOS); `bash greet` ignores the execute bit, `./greet` requires it.

> **TRAINER ONLY.** *Teaching purpose:* separate "a program" (text + interpreter) from
> "permission to execute" (the bit). *Ask:* "Why did `bash greet` work before
> `chmod`?" *Expected:* "because we told bash to read it; the bit only matters when
> the OS has to decide what runs it." *Misconception:* the shebang is a comment. Show
> that `head -1 greet` is read by the kernel when you use `./greet`. *Intervene* if a
> learner's editor is set to CRLF line endings: they produce `bad interpreter:
> No such file or directory` — teach `cat -A` as the diagnostic, then have them re-type
> the file inside the container. Grading relevance: A-01 check "env-bash shebang".

### S00.5 — Exact output with `printf`
- **Purpose.** `echo` behaves differently across shells; `printf` is precise and portable — the right tool when another program will read your output.
- **Exact action.** Change the body so the file is:
  ```bash
  #!/usr/bin/env bash
  printf 'Hello, world!\n'
  ```
  Run `./greet`.
- **Expected observation (observed).** `Hello, world!`
- **Verification.** Exactly that line, ending with a newline (your prompt appears on the next line, not glued to the text).
- **Recovery.** Prompt glued to the output → you omitted `\n`. Literal `\n` printed → you used double quotes around the format with an escaped backslash, or `echo`; use single quotes as shown.
- **Evidence / next state.** `greet` prints a formatted line. **Why:** `printf 'FORMAT' args` places text exactly and adds a newline only where you write `\n`.

> **TRAINER ONLY.** *Demonstrate the difference, don't assert it:* `printf 'a'; printf 'b'`
> (observed `ab`) versus `echo -n` behavior, and mention that `echo` of a string that
> starts with `-e` or contains backslashes is shell-dependent. *Expected answer to
> knowledge check 2:* `ab` because no `\n`. Intervene when learners put the variable
> *inside* the single-quoted format (they will in S00.6).

### S00.6 — Take an argument, with a sensible default
- **Purpose.** Scripts receive arguments as `$1`, `$2`, …; a default keeps the script usable with no argument.
- **Exact action.** Make the file:
  ```bash
  #!/usr/bin/env bash
  name="${1:-world}"
  printf 'Hello, %s!\n' "$name"
  ```
  Run `./greet` and then `./greet Antonio`.
- **Inputs.** Any name as the first argument (a value with spaces must be quoted: `./greet "Ada Lovelace"`).
- **Expected observation (observed).**
  ```text
  Hello, world!
  Hello, Antonio!
  ```
- **Verification.** Both lines as shown.
- **Recovery.** `Hello, !` → you wrote `$1` without the default and ran it with no argument. `Hello, ${1:-world}!` → the expansion is inside single quotes; the variable must be outside the format string, as an argument.
- **Evidence / next state.** Argument handling works. **Why:** `${1:-world}` means "use `$1`, or `world` if it is unset or empty"; `%s` drops the value in exactly there. (Parameter expansion is the whole of M01 — this is a first taste.)

> **TRAINER ONLY.** *Ask:* "What does `./greet ""` print?" *Expected:* `Hello, world!`
> — because `:-` treats *empty* like unset (observed behavior of `${1:-world}`).
> Then show `${1-world}` (no colon) printing `Hello, !` for the empty argument. This
> one-character distinction is the first "accurate mental model over folk rule" moment
> of the course; it returns in M01 and in M09's config parsing. Grading relevance: A-01
> checks "default greeting" and "greets its argument".

### S00.7 — Strict mode: the house header
- **Purpose.** Make an incorrect script fail loudly instead of silently. Every script in this course starts this way.
- **Exact action.** Make the file:
  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  IFS=$'\n\t'

  name="${1:-world}"
  printf 'Hello, %s!\n' "$name"
  ```
  Run `./greet Antonio`.
- **Expected observation (observed).** `Hello, Antonio!` — identical to before.
- **Verification.** Same output; no error. Strict mode changes nothing when the script is correct.
- **Recovery.** `unbound variable` → a typo in a variable name (e.g., `$naem`) — exactly what `-u` is for; fix the spelling. Script exits silently with no output → a command before `printf` failed under `-e`; run `bash -x greet` to see which (M08 covers `-x`).
- **Evidence / next state.** Header in place. **Why each flag:** `-e` exit the moment a command fails; `-u` an **unset** variable is an error, not an empty string; `pipefail` a pipeline fails if *any* stage fails; `IFS=$'\n\t'` split words on newlines/tabs, not spaces (safer for data with spaces). M07 covers the two places `set -e` surprises people.

> **TRAINER ONLY — accuracy guardrail.** Do **not** teach `set -e` as "error handling
> solved." State now, briefly, what M07 proves: `-e` does not fire for a command whose
> status is consumed by `if`/`&&`/`||`, and `(( x++ ))` returns failure when `x` was 0
> (both observed in `labs/lab7-robustness/lab.sh`). Here the message is only: "a
> *correct* script is unchanged by strict mode; an *incorrect* one stops instead of
> continuing with bad data." *Demonstrate `-u`:* change `"$name"` to `"$naem"` and run
> → `greet: line 6: naem: unbound variable`, exit 1. Grading relevance: A-01 check
> "uses strict mode" greps for a line beginning `set -euo pipefail`.

### S00.8 — Exit codes: what your script returns
- **Purpose.** Every command reports success as an **exit code**: `0` success, non-zero failure. This is how scripts chain and how other programs consume yours.
- **Exact action.**
  ```bash
  ./greet >/dev/null; echo "exit code: $?"
  ./greet >/dev/null && echo "it worked"
  false || echo "recovering"
  ```
- **Expected observation (observed).**
  ```text
  exit code: 0
  it worked
  recovering
  ```
- **Verification.** Three lines as shown.
- **Recovery.** `exit code: 127` → command not found (path/name). `exit code: 126` → not executable (`chmod +x`). Anything else non-zero → read the error line printed before it.
- **Evidence / next state.** You can read `$?` and chain with `&&`/`||`. **Why it matters:** later, `logsleuth` returns *distinct* codes — 0 ok, 1 runtime error, 2 usage error, 3 "brute force found" — so a pipeline can branch: `logsleuth bruteforce auth.log || alert`. **The program's proof idiom.** Course 2 proves every gate *red then green*, and it writes the proof the way the first line above does: `python art_gate.py; echo "exit=$?"` — a semicolon, not `&&`, because with `&&` a failing gate would print nothing at all and the failure would be invisible. The companion form is `cosign verify … || echo "REJECTED (expected)"` — the failure *is* the result you wanted to see. You will type `; echo "exit=$?"` two dozen times in Course 2; it means "show me the verdict whatever it is".

> **TRAINER ONLY.** *Ask:* "Why redirect to `/dev/null` before checking `$?`?"
> *Expected:* "to show the code is separate from the output — a program can print
> nothing and still succeed or fail." *Misconception:* `$?` is the output. *Preview:*
> in M09, `stackctl check` returns 3 when the health body mismatches, so
> `stackctl check dev || page-oncall` is the whole alerting integration. The distinct
> codes are the API; make that phrase a refrain.

### S00.9 — Lint it with shellcheck
- **Purpose.** Catch the real mistakes bash lets you make — unquoted variables above all — before they bite.
- **Exact action.** 1) `shellcheck greet`. 2) Temporarily remove the quotes around `"$name"` on the last line (make it `$name`), save, and run `shellcheck greet` again. 3) Put the quotes back; run `shellcheck greet` once more.
- **Expected observation (observed, shellcheck 0.11.0).** Step 1 and 3: **no output** (clean). Step 2:
  ```text
  In greet line 6:
  printf 'Hello, %s!\n' $name
                        ^---^ SC2086 (info): Double quote to prevent globbing and word splitting.

  Did you mean:
  printf 'Hello, %s!\n' "$name"
  ```
- **Verification.** Final run is silent; `echo $?` after it prints `0`.
- **Recovery.** `shellcheck: command not found` → in the container it is installed; in the fallback shell install it (`sudo apt install shellcheck` / `brew install shellcheck`) or skip this step — the rest of the course still runs. Other findings → read the SC code's message; each one names the fix.
- **Evidence / next state.** `greet` is lint-clean. A clean `shellcheck` run is the bar every script in this course meets.

> **TRAINER ONLY — make the bug real, not theoretical (all three observed 2026-10-18,
> bash 5.2.21).** With the quotes removed from `$name`:
> 1. `./greet "Ada Lovelace"` under the **house header** (`IFS=$'\n\t'`) prints
>    `Hello, Ada Lovelace!` — a *space* does **not** split, because the house IFS
>    contains no space. Learners who expect a split here are reasoning from the
>    default IFS; show them why it did not happen.
> 2. In a directory containing files, `./greet '*'` prints one `Hello, <file>!` line
>    **per file** (observed: `Hello, a.txt!`, `Hello, b.txt!`, …) — **globbing** is
>    independent of IFS and is the half of SC2086 people forget.
> 3. `./greet "$(printf 'Ada\tLovelace')"` prints `Hello, Ada!` then `Hello, Lovelace!`
>    — a *tab* **does** split under the house IFS; and the same script **without** the
>    `IFS=` line splits on the space too (`Hello, Ada!` / `Hello, Lovelace!`).
> Teaching line: "IFS only decides *which characters* split; **quoting** is what makes
> the expansion safe regardless of IFS or globbing." That is the exact mechanism R2
> asks for. The SC2086 message text may differ across shellcheck versions; the code is
> stable. Grading relevance: A-01 check "greet is shellcheck-clean" (reported as a
> skipped PASS if shellcheck is absent — see grader).

### S00.10 — Keep it: a usable command on your PATH
- **Purpose.** Finish the life of a script: install it so you can call it from anywhere.
- **Exact action.**
  ```bash
  mkdir -p ~/.local/bin
  cp greet ~/.local/bin/greet
  greet "Cherokee Nation"
  ```
  If `greet` is "not found", add the directory to PATH for this session: `export PATH="$HOME/.local/bin:$PATH"` and retry (to make it permanent, append that line to `~/.bashrc`).
- **Expected observation (observed).** `Hello, Cherokee Nation!`
- **Verification.** The command runs from any directory (`cd / && greet && cd -`).
- **Recovery.** Still "not found" after the `export` → check for a typo in the directory name (`ls ~/.local/bin`). Inside the container, `~/.local/bin` lives in the container's home and is **not** persisted after `exit`; that is expected — your source file in `/course` is what persists.
- **Evidence / next state.** You wrote, hardened, linted, and installed a command-line tool. That is the full life of every script — M01–M08 only add what goes *between* the header and the output.

> **TRAINER ONLY.** *Ask:* "Where does the shell look when you type `greet`?"
> *Expected:* "in each directory listed in `$PATH`, in order." Show `echo "$PATH" | tr
> ':' '\n'`. The container's ephemeral home is a feature here: it previews the idea
> that an *environment* is disposable and the *source* is the truth — the core
> intuition of infrastructure as code that M09 makes explicit.

### S00.11 — Unpack what the program ships: `tar`
- **Purpose.** Every download in Courses 1–3 is a `.tar.gz` (`secmlops-infra.tar.gz`, `secmlops-app.tar.gz`, the milestone repositories); Course 2's first command on the application is `tar xzf secmlops-app.tar.gz && cd secmlops-app`. Learn the three verbs once.
- **Exact action.**
  ```bash
  mkdir -p demo-app/src && printf 'print("hi")\n' > demo-app/src/serve.py && printf 'fastapi\n' > demo-app/requirements.txt
  tar czf demo-app.tar.gz demo-app        # c = create, z = gzip, f = this file
  rm -rf demo-app
  tar tzf demo-app.tar.gz                 # t = list, without extracting
  tar xzf demo-app.tar.gz && ls demo-app  # x = extract, into the current directory
  mkdir -p elsewhere && tar xzf demo-app.tar.gz -C elsewhere && ls elsewhere
  ```
- **Expected observation (observed).**
  ```text
  demo-app/
  demo-app/src/
  demo-app/src/serve.py
  demo-app/requirements.txt
  requirements.txt
  src
  demo-app
  ```
- **Verification.** The list shows four entries all starting with `demo-app/`; the extracted folder contains `requirements.txt` and `src`; the copy in `elsewhere/` is the same tree.
- **Recovery.** `tar: demo-app: Cannot stat: No such file or directory` on the first `tar` → the `mkdir`/`printf` line did not run (a typo in the `&&` chain stops it). Files land in the current directory instead of a folder → the archive was created without a top-level directory; always `tar tzf` first to see where things will go. `gzip: stdin: not in gzip format` → the file is not gzip-compressed (`file name.tar.gz` tells you); drop the `z`.
- **Evidence / next state.** **Why `t` before `x`:** an archive may unpack a hundred files into *your current directory*; listing first is how you avoid that. **In the program:** Course 1 Module 0 and Course 2's project page start with `tar xzf …`; Course 2 Lab 4.1 installs a scanner with `curl -sL URL | tar xz` — the same `x` and `z`, reading the archive from a pipe instead of a file — and then `sudo mv gitleaks /usr/local/bin`, which is S00.10's "put it on your PATH" done system-wide.

> **TRAINER ONLY (added Batch 7, 2026-10-26; observed, GNU tar 1.35).** *Why this step exists:* every Course 1–3 download is a tarball and Course 2's first command on the application is `tar xzf …`; the audit found no `tar` anywhere in the course. *Ask:* "What would `tar xzf` have done if the archive had no top-level `demo-app/` directory?" *Expected:* "spilled four files into the current directory" — hence `t` first. *Watch for:* learners who `rm -rf demo-app` *before* the `tar czf` (nothing to archive → `Cannot stat`). The `curl -sL URL | tar xz` form in Lab 4.1 is worth a sentence on trust: piping an unverified download into `tar` (or `sh`) is a supply-chain decision, which is Course 2 Chapter 8's subject — do not teach it as a habit, only as something they will read.

---

## Worked demonstration (watch it prove itself — 10 min)

From the course root, run the worked walkthrough for this module. It replays every
claim above against a fresh script and the `logsleuth` skeleton and grades itself:

```bash
cd /course          # or your course folder in the fallback shell
bash labs/lab0-first-script/lab.sh
```

**Expected observation (observed).** Section headers, one line per check, and the summary:
```text
== a script is text + a shebang + the execute bit ==
  PASS: the shebang names the interpreter
  PASS: run with 'bash hello.sh'
  ...
---- lab0: 19 passed, 0 failed ----
```
Read the `lab.sh` source beside the output: it is the same moves you just made, with
an assertion after each. (`grade-all.sh` runs every exercise's grader at once —
your dashboard for the whole course.)

**How this becomes `logsleuth`.** The project's entry point is built on the exact frame you just learned:
```bash
head -6 logsleuth/bin/logsleuth      # shebang + comments + 'set -euo pipefail'
bash logsleuth/bin/logsleuth version
bash logsleuth/bin/logsleuth help
```
Observed: the header ends with `set -euo pipefail`; `version` prints `logsleuth 1.0.0`; `help` begins `logsleuth 1.0.0 — analyze access and auth logs` and a `usage:` block.

> **TRAINER ONLY — what `lab.sh` actually asserts (19 checks, observed).** Shebang and
> two run methods; argument changes output; execute bit; `exit 0`/`exit 7` codes;
> `&&`/`||`; `printf` exactness and no implicit newline; `set -u` aborting on an unset
> variable vs silent empty without it; `pipefail` surfacing a mid-pipe failure; the
> strict header script running and being shellcheck-clean; `logsleuth version`/`help`;
> the whole project shellcheck-clean. Use it as your answer key for "did the course's
> claims hold on this machine": if any line is FAIL in a learner's environment, that
> is an *environment* finding (report it), not a learner error.

---

## LAB-00 — Your exercise (graded as A-01) — 30 min

**Task.** Build `greet` *as the grader expects it*, in the exercise's working copy.

| Field | Value |
|---|---|
| Location | `labs/lab0-first-script/exercise/` (read `TASK.md` there) |
| Starting assets | `starter/greet` — the skeleton with `# TODO` lines; `grade.sh` — the grader |
| Allowed resources | This module, any documentation, AI assistance (disclose in reflection) |
| Deliverables | `work/greet` passing the grader; `work/REFLECTION.md` with two answers (below) |
| Acceptance | `bash grade.sh` ends `---- lab0: 6 passed, 0 failed ----`; both reflection answers present |

**Procedure.**
1. `cd labs/lab0-first-script/exercise && bash grade.sh` — the first run copies the starter into `work/` and grades it. **Observed:** `---- lab0: 2 passed, 4 failed ----`. The FAIL lines are your to-do list.
2. Edit `work/greet`: add the two header lines, set `name="${1:-world}"`, and print with `printf 'Hello, %s!\n' "$name"` (the TODO comments quote each line).
3. Re-run `bash grade.sh` until **`---- lab0: 6 passed, 0 failed ----`** (observed with the reference solution). Checks: default greeting, greets its argument, exits 0, env-bash shebang, strict mode present, shellcheck-clean.
4. Create `work/REFLECTION.md` answering, in your own words (3–5 sentences each):
   - **R1.** Why does the course use `printf` instead of `echo` for output that another program might read?
   - **R2.** What would break, and when, if you forgot the quotes around `"$name"`? Relate it to the SC2086 message you saw.

**Learner-visible rubric (A-01).** *Pass* = grader `0 failed` **and** both reflections
answer the question asked (not a restatement). *Not yet* = any FAIL, or a reflection
missing/generic. Re-run the grader after each fix; there is no limit on attempts.

**Hints (graduated).** H1: run `bash grade.sh` and read only the first FAIL. H2: the
expected text in each FAIL is exactly what your script should print. H3: compare your
header to S00.7 character by character. (The reference answer is in the Trainer
Edition; the goal is a green grader you produced.)

**Reset / cleanup.** To start over: `rm -rf work && bash grade.sh`. Nothing else to clean up.

**Accessibility note.** Every check is text; no step depends on color or a screenshot.
A screen reader can read grader output line by line; `grade.sh 2>&1 | less` pages it.

> **TRAINER ONLY — complete solution (reference `solution/greet`, observed 6/6):**
> ```bash
> #!/usr/bin/env bash
> set -euo pipefail
> IFS=$'\n\t'
>
> name="${1:-world}"
> printf 'Hello, %s!\n' "$name"
> ```
> *Acceptable variations:* `printf 'Hello, %s!\n' "${1:-world}"` without the variable
> (passes all six checks); omitting `IFS=$'\n\t'` (passes — the grader checks only the
> `set -euo pipefail` line; coach toward the full header anyway); `#!/bin/bash` **fails**
> the shebang check by design — explain portability. Any `echo`-based version that
> prints the exact lines passes the output checks; use R1 to make the learner justify
> or change it.
>
> **Grading procedure (≈5 min/learner).**
> 1. Grade their copy without touching it: `GRADE_TARGET=/path/to/their/work bash
>    labs/lab0-first-script/exercise/grade.sh` → require `---- lab0: 6 passed, 0 failed ----`.
>    If shellcheck is absent on your machine the last check reports a skipped PASS —
>    re-run where shellcheck exists before certifying.
> 2. Read `REFLECTION.md` against the descriptors:
>    - **R1 — Met:** names that `echo` varies across shells/flags or backslashes and
>      that `printf` gives exact, controllable formatting, so machine-readable output is
>      predictable. **Strong:** also mentions the newline being explicit (`\n`) or gives
>      a concrete failure (`echo -e`/backslash differences). **Not met:** "printf is
>      better/more modern" with no mechanism.
>    - **R2 — Met:** says an unquoted `$name` is subject to **word splitting on the
>      characters in IFS** and to **globbing**, so a value containing such a character
>      (or `*`) becomes several arguments or filenames — which is what SC2086 warns
>      about. **Strong:** notes that under the course's `IFS=$'\n\t'` a space is safe
>      but a tab/newline still splits and `*` still expands to filenames, so quoting —
>      not IFS — is the real protection; or gives an observed outcome (`Hello, a.txt!`
>      per file for `'*'`). **Not met:** "it would error" (it does not error — it
>      misbehaves silently; correct this misconception explicitly) or "a space would
>      split it" stated as universal (true only for the default IFS; probe for the
>      mechanism).
> 3. Record: `A-01 PASS` only when grader is 6/6 **and** both reflections are at least
>    *Met*. No partial credit; no critical gates in A-01.
>
> **Calibration examples.** *R2, Met:* "Without quotes, bash splits `$name` on the
> characters in IFS and also expands glob patterns before `printf` sees it, so a value
> like `*` turns into every filename in the folder and the format runs once per
> argument. SC2086 is warning about exactly that splitting and globbing." *R2, Strong:*
> adds "with the course's IFS a plain space is actually safe, but a tab would still
> split and `*` still globs — so the fix is the quotes, not the IFS." *R2, Not met:*
> "Shellcheck would complain so it is bad practice." (names the symptom, not the
> mechanism — return with the hint: "what does the script *print* when the argument
> is `*`?")
>
> **Model feedback (Not yet):** "Your grader shows `FAIL: uses strict mode` — compare
> line 2 of your file with S00.7; the check looks for `set -euo pipefail` at the start
> of a line." **Remediation:** re-do S00.7 and S00.9 only. **Equivalent reassessment:**
> same grader; replace R1/R2 with **R1'** "Why does `${1:-world}` use a colon?" (Met:
> treats empty like unset) and **R2'** "What does `set -u` protect you from, with an
> example?" (Met: a misspelled variable aborting instead of expanding to nothing).
>
> **Evidence handling.** Keep the grader's final output and `REFLECTION.md` per learner
> (text only; no personal data beyond their name). **Reset for the next session:**
> learners may delete `work/` (`rm -rf work`); nothing else persists.

---

## Knowledge checks (predict, then run)

1. After `chmod +x greet`, which of these runs it: `bash greet`, `./greet`, or both?
2. What does `printf 'a'; printf 'b'` print, and why?
3. In `name="${1:-world}"`, when does `world` get used?
4. Under `set -u`, what happens on `echo "$naem"` (a typo)?
5. Which exit code means success, and what does `A || B` do?
6. Course 2 writes `python art_gate.py; echo "exit=$?"`. What would change if the `;` were `&&`?
7. What does `tar tzf archive.tar.gz` do, and why run it before `tar xzf`?
> **TRAINER ONLY — answers and why the tempting alternatives are wrong.**
> 1. Both. Tempting: "only `./greet`" — forgets that `bash file` reads the file itself.
> 2. `ab`. Tempting: two lines — assumes an implicit newline like `echo`'s.
> 3. When `$1` is unset **or empty**. Tempting: "only when missing" — that is the
> colon-less form `${1-world}`.
> 4. The script aborts (`naem: unbound variable`, exit 1). Tempting: "prints an empty
> line" — true only *without* `-u`, which is the whole point.
> 5. `0`; `A || B` runs B only if A fails. Tempting: "`||` means or, so both run" —
> confuses boolean OR with short-circuit control flow.

---

## In the SecMLOps Program
This course is **Course 0** of the SecMLOps program: everything the three courses ask you to type in a terminal is bash, and this is where you learn to read it rather than copy it. The first script you meet in the program after this one is Course 2's `scripts/ready-check.sh` ("is my computer ready?") — a `#!/usr/bin/env bash` file with `set -u`, a handful of `printf` functions and `command -v` tests exactly like today's `tools-check.sh`; Course 1 wraps the same idea as `make ready`. Course 1 keeps Docker on the lab VM rather than on your laptop, and Course 2 builds an image on the laptop only once (Lab 7.1) — the Docker you install in S00.1 is what makes that step, and M09's `stackctl`, possible without a VM. The program's rule is that a later course never installs what an earlier one produced; this course produces your shell skills and a working Docker.

---

<!-- os:windows -->
**Windows 11 — what carries over.** You are learning bash inside WSL 2 Ubuntu. Courses 1 and 2 run their *laptop-side* commands in **Git Bash** (installed with Git for Windows — GNU coreutils, `sed -i`, `sha256sum`, here-documents all work as written) or **on the lab VM** over `make ssh`, and WSL 2 Ubuntu works for the laptop side too; the Course 2 page *Running the labs on Ubuntu, macOS, and Windows 11* lists the differences. Everything in this course transfers; the four things to know: in Git Bash the Python binary is `python`, not `python3` (add `alias python3=python` to `~/.bashrc`); `sudo` does not exist there and is never needed on the laptop; `make` is not installed by default (`winget install ezwinports.make`, or use `.\lab.ps1` from PowerShell); and `flock`, Docker and the scanners live on the VM, not in Git Bash.
<!-- /os -->
<!-- os:windows -->
> **TRAINER ONLY — platform bridge (Batch 7).** Course 2's *Running the labs* page recommends Git Bash on Windows and does not mention WSL 2; Course 0 teaches in WSL 2. Both work for Course 2's laptop-side steps; tell Windows learners they may keep WSL 2 for the laptop side if they prefer, and that the VM-side steps are identical for everyone. Raise with the program owner whether that Course 2 page should list WSL 2 as the third option (recorded in the manifest).
<!-- /os -->
<!-- os:macos -->
**macOS — what carries over.** Course 2 asks every Mac student to install the GNU tools once and put them first on `PATH` (`brew install coreutils gnu-sed findutils grep` plus one `export PATH=…` line, on its *Running the labs on Ubuntu, macOS, and Windows 11* page) so that the labs run as written. This course's Environment page has you do the same thing in section 8 — so `sed -i`, `sha256sum`, `base64 -w0`, `timeout` and `readlink -f` behave here exactly as they will there, and the BSD substitutions (`sed -i ''`, `shasum -a 256`) are only for a Mac where that step was skipped.
<!-- /os -->
<!-- os:macos -->
> **TRAINER ONLY — platform bridge (Batch 7).** Until 2026-10-26 the macOS edition carried a BSD `sed -i ''` variant for M09 and told Mac learners that `flock` steps needed the container. Both conflicted with Course 2, which installs the GNU tools once; the Environment page now does the same (section 8, plus `brew install flock`), so M09/CAP-01 run as written on a Mac. None of this was observed on a Mac in the authoring environment — V-01 confirms it.
<!-- /os -->

## Recap and transfer
You can now write, run, and reason about a script: shebang, execute bit, exact
output, arguments with defaults, strict mode, exit codes, a clean lint, and an
install. **Transfer:** M01 reuses the same frame to build `logsleuth`'s name and
config helpers; M09's infrastructure scripts start with this exact header.

---

## Self-check answers (read after attempting)

**D-01.** 1 `#!/usr/bin/env bash` as line 1 · 2 `chmod +x file; ./file` · 3 `printf 'Hello, World!\n'` · 4 `"${1:-default}"` · 5 the exit code of the last command (0 = success) · 6 `"$path"` · 7 `-e` exit on failure, `-u` unset variable is an error, `-o pipefail` any failing pipeline stage fails the pipeline · 8 `&&` runs B only if A succeeded; `||` runs B only if A failed · 9 `shellcheck script` · 10 `cp script ~/.local/bin/ && script`.

**Knowledge checks.** 1 Both — `bash greet` never needed the bit; `./greet` does. 2 `ab` on one line: `printf` adds no newline unless you write `\n`. 3 When `$1` is unset *or empty* (`:-`); `${1-world}` without the colon would use an empty argument as-is. 4 The script aborts with `naem: unbound variable` — that is the protection, not a bug. 5 `0`; `A || B` runs B only when A fails (exit non-zero). 6 With `&&`, `echo` runs only when the gate *succeeds* — a failing gate would print nothing, so the red run would leave no evidence; the `;` prints the status either way (S00.8). 7 It *lists* the archive without extracting (observed: four entries under `demo-app/`), so you can see whether it unpacks into a folder or straight into your current directory before you let it (S00.11).

> **TRAINER ONLY — end of module.** Debrief prompt: "What is the one thing strict mode
> did *not* do for you?" (expected: it did not catch a logic error such as the wrong
> default — only crashes/unset variables). **Prepare M01:** have learners keep the
> container running; M01 needs no new tools. **Session close:** confirm each learner's
> A-01 status in your record; collect no files other than `work/greet` and
> `work/REFLECTION.md`.
