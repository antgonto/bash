# M00 — Orientation, your environment, and your first script
**Student Edition · curriculum v2.0.0-draft · self-paced, no fixed duration**

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

---

## Activity context for S00.1–S00.3 (environment)

| Field | Value |
|---|---|
| Execution context | **Your computer's own terminal**, in the unzipped course folder. Supported platforms, the same as the rest of the program: **Ubuntu/Debian** (22.04 or later; any terminal), **macOS** (Intel or Apple Silicon; Terminal or iTerm), **Windows 11** — *inside WSL 2 Ubuntu*: every command in this course is typed in the Ubuntu terminal that WSL gives you, never in PowerShell. (Windows 11 support added 2026-10-21; before that the course was published for **macOS** and **Ubuntu**.) |
| Starting state | Course bundle unzipped; you can open a terminal in that folder |
| Permissions | Administrator/sudo rights for Step S00.1 only |
| Cost | No paid service required; see Docker Desktop licensing note in `env/README.md` |
| Validation status | Steps S00.1–S00.3 are **designed, not executed** by the course authors (no Docker daemon in the authoring environment). Expected observations below are illustrative; verification task V-01 is open. |

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

---

## Knowledge checks (predict, then run)

1. After `chmod +x greet`, which of these runs it: `bash greet`, `./greet`, or both?
2. What does `printf 'a'; printf 'b'` print, and why?
3. In `name="${1:-world}"`, when does `world` get used?
4. Under `set -u`, what happens on `echo "$naem"` (a typo)?
5. Which exit code means success, and what does `A || B` do?
6. Course 2 writes `python art_gate.py; echo "exit=$?"`. What would change if the `;` were `&&`?
7. What does `tar tzf archive.tar.gz` do, and why run it before `tar xzf`?

---

## In the SecMLOps Program
This course is **Course 0** of the SecMLOps program: everything the three courses ask you to type in a terminal is bash, and this is where you learn to read it rather than copy it. The first script you meet in the program after this one is Course 2's `scripts/ready-check.sh` ("is my computer ready?") — a `#!/usr/bin/env bash` file with `set -u`, a handful of `printf` functions and `command -v` tests exactly like today's `tools-check.sh`; Course 1 wraps the same idea as `make ready`. Course 1 keeps Docker on the lab VM rather than on your laptop, and Course 2 builds an image on the laptop only once (Lab 7.1) — the Docker you install in S00.1 is what makes that step, and M09's `stackctl`, possible without a VM. The program's rule is that a later course never installs what an earlier one produced; this course produces your shell skills and a working Docker.

---

<!-- os:windows -->
**Windows 11 — what carries over.** You are learning bash inside WSL 2 Ubuntu. Courses 1 and 2 run their *laptop-side* commands in **Git Bash** (installed with Git for Windows — GNU coreutils, `sed -i`, `sha256sum`, here-documents all work as written) or **on the lab VM** over `make ssh`, and WSL 2 Ubuntu works for the laptop side too; the Course 2 page *Running the labs on Ubuntu, macOS, and Windows 11* lists the differences. Everything in this course transfers; the four things to know: in Git Bash the Python binary is `python`, not `python3` (add `alias python3=python` to `~/.bashrc`); `sudo` does not exist there and is never needed on the laptop; `make` is not installed by default (`winget install ezwinports.make`, or use `.\lab.ps1` from PowerShell); and `flock`, Docker and the scanners live on the VM, not in Git Bash.
<!-- /os -->
<!-- os:macos -->
**macOS — what carries over.** Course 2 asks every Mac student to install the GNU tools once and put them first on `PATH` (`brew install coreutils gnu-sed findutils grep` plus one `export PATH=…` line, on its *Running the labs on Ubuntu, macOS, and Windows 11* page) so that the labs run as written. This course's Environment page has you do the same thing in section 8 — so `sed -i`, `sha256sum`, `base64 -w0`, `timeout` and `readlink -f` behave here exactly as they will there, and the BSD substitutions (`sed -i ''`, `shasum -a 256`) are only for a Mac where that step was skipped.
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
