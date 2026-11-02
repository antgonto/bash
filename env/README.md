# Environment (Docker) — setup, step by step

The course runs in one small Docker container (`bash-course:2.0`) so every learner has the
same bash, tools and versions, and nothing is installed on your computer beyond Docker
itself. Modules M00–M08 run *inside* that container; M09 and the capstone run on your own
shell and use Docker to run the program's project. This page takes a computer with nothing
installed to a working lab session. Do the sections in order; each one ends with a check.

**Validation status.** The image definition (`env/Dockerfile`) is *designed and reviewed*,
not yet *built or executed* — the authoring environment had no Docker daemon (verification
task **V-01**, section 9). The installation commands below follow Docker's<!-- os:all windows --> and Microsoft's<!-- /os --> documented
procedure for each platform as of this writing, but the install pages themselves were not
re-accessed (verification task **V-02**); if a command differs from what the vendor's site
shows today, the site wins — tell the course owner.

<!-- os:all -->
**Platforms** (the same set as Courses 1 and 2 of the program): **Ubuntu/Debian** 22.04+
/ Debian 12, **macOS** (Apple Silicon or Intel), **Windows 11 inside WSL 2 Ubuntu**. On
Windows every command in this course is typed in the Ubuntu shell, never in PowerShell —
PowerShell is used exactly once, to install WSL. *(Windows 11 support added 2026-10-21;
before that the course was published for macOS and Ubuntu only.)*

<!-- /os -->
<!-- os:ubuntu -->
**This is the Ubuntu/Debian edition** (Ubuntu 22.04+ or Debian 12). The macOS and Windows 11 editions are separate downloads with the same content; the program's host-OS list is the same across Courses 0, 1 and 2.

<!-- /os -->
<!-- os:macos -->
**This is the macOS edition** (Apple Silicon or Intel). The Ubuntu/Debian and Windows 11 editions are separate downloads with the same content; the program's host-OS list is the same across Courses 0, 1 and 2.

<!-- /os -->
<!-- os:windows -->
**This is the Windows 11 edition** — the course runs *inside WSL 2 Ubuntu*: every command is typed in the Ubuntu shell, never in PowerShell, which is used exactly once, to install WSL. The Ubuntu/Debian and macOS editions are separate downloads with the same content; the program's host-OS list is the same across Courses 0, 1 and 2.

<!-- /os -->
---

## 0. Which path are you on?

| Your computer | Do sections | Shell you will type in |
| --- | --- | --- |
<!-- os:ubuntu -->
| Ubuntu or Debian laptop | 1 · 2 · 5 · 6 · 7 | the Terminal (`Ctrl+Alt+T`) |
<!-- /os -->
<!-- os:macos -->
| macOS (Apple Silicon or Intel) | 1 · 3 · 5 · 6 · 7 | Terminal.app (Spotlight → *Terminal*) |
<!-- /os -->
<!-- os:windows -->
| Windows 11 | 1 · 4 (which uses 2) · 5 · 6 · 7 | the **Ubuntu** window that WSL installs (section 4) |
<!-- /os -->
| Already finished Course 1 | 1 (inside the VM) · 5 · 6 · 7 | `vagrant ssh lab` — the lab VM is Ubuntu with Docker Engine already installed by `make provision`; skip sections 2–4 |
| No Docker possible right now | 1 · 8 | your own shell; M00–M08 only |

Section numbers are shared with the other platform editions, so this edition may skip a number (for example, the macOS edition has no sections 2 and 4). References such as "go to section 5" are always right.

Requirements for every path: about **4 GB of free disk** (Docker itself, the course image,
and in M09 the fraud-clf image), an internet connection for the installs and the first
image pulls/builds, and the ability to run commands as administrator on your own machine.

---

## 1. Get the course files

1. Download `bash-course-student.zip` from your course area (Moodle) to your computer.
<!-- os:all -->
2. Create one folder for the program and unzip there (on Windows: in the Ubuntu shell; `~/` is your Linux home, not `C:\Users`):
   ```bash
   mkdir -p ~/secmlops && cd ~/secmlops
   unzip ~/Downloads/bash-course-student.zip      # wherever the browser saved it
   cd ~/secmlops/bash-course-student
   ls
   ```
   **Expected:** `README.md  env  grade-all.sh  labs  logsleuth  seed  student  tools-check.sh`.
   On WSL 2 the Windows Downloads folder is reachable as `/mnt/c/Users/<you>/Downloads/`;
   copy the zip into `~/secmlops` first (`cp /mnt/c/Users/<you>/Downloads/bash-course-student.zip ~/secmlops/`)
   — working under `/mnt/c` is slow and breaks file permissions.
<!-- /os -->
<!-- os:ubuntu macos -->
2. Create one folder for the program and unzip there (`~/` is your home folder):
   ```bash
   mkdir -p ~/secmlops && cd ~/secmlops
   unzip ~/Downloads/bash-course-student.zip      # wherever the browser saved it
   cd ~/secmlops/bash-course-student
   ls
   ```
   **Expected:** `README.md  env  grade-all.sh  labs  logsleuth  seed  student  tools-check.sh`.
<!-- /os -->
<!-- os:windows -->
2. **Do section 4a first** if you have not yet installed WSL — the rest of this section happens in the Ubuntu window. Create one folder for the program and unzip there (`~/` is your Linux home, not `C:\Users`):
   ```bash
   mkdir -p ~/secmlops && cd ~/secmlops
   cp /mnt/c/Users/<you>/Downloads/bash-course-student.zip ~/secmlops/     # <you> = your Windows user name
   unzip bash-course-student.zip
   cd ~/secmlops/bash-course-student
   ls
   ```
   **Expected:** `README.md  env  grade-all.sh  labs  logsleuth  seed  student  tools-check.sh`. The Windows Downloads folder is reachable from Ubuntu as `/mnt/c/Users/<you>/Downloads/`; always copy the zip into `~/secmlops` first — working under `/mnt/c` is slow and breaks file permissions.
<!-- /os -->
<!-- os:all ubuntu windows -->
3. If `unzip` is missing: `sudo apt-get install -y unzip`.
<!-- /os -->
<!-- os:macos -->
3. `unzip` is built into macOS (double-clicking the zip in Finder also works).
<!-- /os -->

From here on, "the course folder" means `~/secmlops/bash-course-student`. Every command
in this page is run from there unless it says otherwise.

---

<!-- os:all ubuntu -->
## 2. Ubuntu / Debian — install Docker Engine (≈ 10 min)

Install from **Docker's own apt repository**. Do **not** use `sudo apt install docker.io`
(the distro's package is older and lacks the Compose plugin) and do not install the old
standalone `docker-compose` v1 binary — this course uses the `docker compose` plugin.

1. Open a terminal and remove any conflicting packages (safe if none are installed):
   ```bash
   sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
   ```
2. Install the prerequisites and add Docker's signing key:
   ```bash
   sudo apt-get update
   sudo apt-get install -y ca-certificates curl
   sudo install -m 0755 -d /etc/apt/keyrings
   sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
   sudo chmod a+r /etc/apt/keyrings/docker.asc
   ```
   **Debian:** use `https://download.docker.com/linux/debian/gpg` instead.
3. Add the repository:
   ```bash
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
     https://download.docker.com/linux/ubuntu \
     $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" \
     | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   sudo apt-get update
   ```
   **Debian:** replace `linux/ubuntu` with `linux/debian`.
   **Expected:** the `apt-get update` output includes a line from `download.docker.com`.
4. Install Docker Engine, the CLI, containerd and the two plugins:
   ```bash
   sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   ```
5. Let your user run Docker without `sudo`, then **log out and back in** (or run `newgrp docker`
   in the current terminal as a temporary measure):
   ```bash
   sudo usermod -aG docker "$USER"
   ```
6. Make sure the daemon runs now and at every boot:
   ```bash
   sudo systemctl enable --now docker
   ```
7. Check — go to section 5.

---

<!-- /os -->
<!-- os:windows -->
## 2. Ubuntu — install Docker Engine inside WSL (≈ 10 min; called from section 4b)

Install from **Docker's own apt repository**, in the Ubuntu window. Do **not** use `sudo apt install docker.io`
(the distro's package is older and lacks the Compose plugin) and do not install the old
standalone `docker-compose` v1 binary — this course uses the `docker compose` plugin.

1. Remove any conflicting packages (safe if none are installed):
   ```bash
   sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
   ```
2. Install the prerequisites and add Docker's signing key:
   ```bash
   sudo apt-get update
   sudo apt-get install -y ca-certificates curl
   sudo install -m 0755 -d /etc/apt/keyrings
   sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
   sudo chmod a+r /etc/apt/keyrings/docker.asc
   ```
3. Add the repository:
   ```bash
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
     https://download.docker.com/linux/ubuntu \
     $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" \
     | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   sudo apt-get update
   ```
   **Expected:** the `apt-get update` output includes a line from `download.docker.com`.
4. Install Docker Engine, the CLI, containerd and the two plugins:
   ```bash
   sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   ```
5. Let your user run Docker without `sudo`:
   ```bash
   sudo usermod -aG docker "$USER"
   ```
   The group takes effect after WSL restarts — section 4b does that.
6. Go back to section 4b, step 2.

---

<!-- /os -->
<!-- os:macos -->
## 3. macOS — install Docker Desktop (≈ 10 min)

1. Find out which Mac you have: Apple menu → *About This Mac*. "Apple M1/M2/M3/M4" means
   **Apple Silicon**; "Intel" means **Intel**.
2. Download Docker Desktop for Mac from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/),
   choosing the build that matches step 1. (Alternative, if you already use Homebrew:
   `brew install --cask docker`.)
3. Open the downloaded `.dmg` and drag **Docker** to **Applications**.
4. Open **Docker** from Applications. Accept the service agreement; allow the privileged
   helper when macOS asks for your password. Wait until the whale icon in the menu bar
   stops animating and the Docker window says **Engine running**.
5. Open **Terminal** (Spotlight → *Terminal*).
6. **Install bash 5 and the GNU tools once (≈ 5 min) — the same step Course 2 asks of every
   Mac student.** The system `bash` is 3.2 and `sed`, `date`, `base64`, `stat` and friends are
   the BSD versions; M00–M08 run inside the course container (GNU everything), but M09 and
   CAP-01 run on your own shell. Install Homebrew if you do not have it (one command, shown
   at [brew.sh](https://brew.sh)), then:
   ```bash
   brew install bash shellcheck flock coreutils gnu-sed findutils grep jq python3
   printf '%s\n' 'export PATH="$(brew --prefix)/opt/coreutils/libexec/gnubin:$(brew --prefix)/opt/gnu-sed/libexec/gnubin:$(brew --prefix)/opt/findutils/libexec/gnubin:$(brew --prefix)/opt/grep/libexec/gnubin:$PATH"' >> ~/.zshrc
   printf '%s\n' 'export PATH="$(brew --prefix)/opt/coreutils/libexec/gnubin:$(brew --prefix)/opt/gnu-sed/libexec/gnubin:$(brew --prefix)/opt/findutils/libexec/gnubin:$(brew --prefix)/opt/grep/libexec/gnubin:$PATH"' >> ~/.bash_profile
   ```
   Close and reopen Terminal, then check: `bash --version` → `5.x`; `sed --version` → `GNU sed`;
   `flock --version` prints a version. The `PATH` line is the one from Course 2's *Running the
   labs on Ubuntu, macOS, and Windows 11* page, written to both shell start-up files so that it
   applies in zsh (the macOS default) and in bash. From here on every command in this course
   and in Course 2 runs as written on your Mac; the BSD substitutions (`sed -i ''`, `shasum -a 256`,
   `stat -f`) are only for a Mac where this step was skipped. *(This step is documented from the
   Homebrew formulae — `flock` is the discoteq `flock` port — and was not executed on a Mac by
   the course authors; V-01 confirms it.)*
7. Go to section 5.

**Licensing note.** Docker Desktop's terms depend on organization size and change over
time; confirm the current terms for your situation at docker.com before relying on it for
a cohort. Docker Engine on Linux is open source. No paid service is required by this course.

---

<!-- /os -->
<!-- os:windows -->
## 4. Windows 11 — install WSL 2 Ubuntu, then Docker Engine inside it (≈ 20 min)

### 4a. WSL 2 and Ubuntu

1. Open **PowerShell as Administrator** (Start → type *PowerShell* → *Run as administrator*).
   This is the only time PowerShell is used in this course.
2. Install WSL with the Ubuntu distribution:
   ```powershell
   wsl --install -d Ubuntu
   ```
   If WSL was already present, this installs only Ubuntu. If it says WSL is already
   installed and Ubuntu already exists, skip to step 5.
3. **Reboot** when asked.
4. After the reboot an **Ubuntu** window opens on its own (if not: Start → *Ubuntu*). It
   asks for a new UNIX username and password — choose a short lowercase name; the password
   is what `sudo` will ask for. This account is separate from your Windows account.
5. Confirm it is WSL **2** — in PowerShell (any user):
   ```powershell
   wsl -l -v
   ```
   **Expected:** a line `Ubuntu … 2`. If the VERSION column shows `1`:
   `wsl --set-version Ubuntu 2`, then `wsl --set-default-version 2`.
6. Close PowerShell. **From now on, everything happens in the Ubuntu window.**

### 4b. Docker Engine inside Ubuntu (recommended)

1. In the Ubuntu window, run **section 2, steps 1–5** exactly as written (it is Ubuntu).
2. Make the daemon start automatically with WSL by enabling systemd in the distro:
   ```bash
   printf '[boot]\nsystemd=true\n' | sudo tee /etc/wsl.conf
   ```
   Then, in PowerShell or the Windows Start menu, restart WSL: `wsl --shutdown`, and open
   the Ubuntu window again. Now:
   ```bash
   sudo systemctl enable --now docker
   ```
   *If you prefer not to enable systemd:* skip the `wsl.conf` line and run
   `sudo service docker start` each time you open Ubuntu (it will print
   `Starting Docker: docker.` — that is success).
3. Check — go to section 5. Docker, the course image and all your files live inside WSL;
   Windows never sees them unless you look under `\\wsl$\Ubuntu\home\<you>` in Explorer.

### 4c. Alternative: Docker Desktop for Windows with WSL integration

If your organization already standardizes on Docker Desktop: install it from
[docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) (choose *WSL 2 backend* during setup),
open it, then *Settings → Resources → WSL integration* → enable **Ubuntu** → *Apply &
restart*. Skip 4b. The `docker` command then works inside the Ubuntu window with no daemon
to start. **Licensing note:** Docker Desktop's terms depend on organization size and change
over time; confirm the current terms for your situation at docker.com. Docker Engine (4b) is
open source. No paid service is required by this course.

### 4d. Read before you start Course 1

WSL 2 runs on the Hyper-V hypervisor. Course 1 Module 0 suggests turning that off
(`bcdedit /set hypervisorlaunchtype off`) for a faster VirtualBox. **Finish Course 0
first.** Then either keep Hyper-V on (slower lab VM; WSL 2 keeps working), or turn it off
for Course 1 and back on (`bcdedit /set hypervisorlaunchtype auto`, reboot) when you need
WSL 2 again. Running Course 0 inside the Course 1 lab VM avoids the conflict entirely.

---

<!-- /os -->
## 5. Check that Docker works

In your terminal<!-- os:all ubuntu macos --> (the shell named in section 0)<!-- /os --><!-- os:windows --> — the Ubuntu window<!-- /os -->:

```bash
docker version
docker compose version
docker run --rm hello-world
```

**Expected:**
- `docker version` prints **two** sections, `Client:` and `Server:`, each with a version.
- `docker compose version` prints `Docker Compose version v2.x.x` or later.
- `hello-world` pulls a tiny image and prints `Hello from Docker!`.

| If you see | It means | Do |
| --- | --- | --- |
<!-- os:all -->
| `Server:` section missing / `Cannot connect to the Docker daemon` | the daemon is not running | macOS: open Docker Desktop and wait for *Engine running*. Ubuntu: `sudo systemctl start docker`. WSL 2 without systemd: `sudo service docker start`. |
<!-- /os -->
<!-- os:ubuntu -->
| `Server:` section missing / `Cannot connect to the Docker daemon` | the daemon is not running | `sudo systemctl start docker` (and `sudo systemctl enable docker` so it survives a reboot). |
<!-- /os -->
<!-- os:macos -->
| `Server:` section missing / `Cannot connect to the Docker daemon` | Docker Desktop is not running | open Docker from Applications and wait for *Engine running*. |
<!-- /os -->
<!-- os:windows -->
| `Server:` section missing / `Cannot connect to the Docker daemon` | the daemon is not running | with systemd enabled: `sudo systemctl start docker`; without: `sudo service docker start`; with Docker Desktop: open it and check WSL integration is on for Ubuntu. |
<!-- /os -->
<!-- os:all -->
| `permission denied while trying to connect to the Docker daemon socket` | your user is not in the `docker` group yet | `sudo usermod -aG docker "$USER"`, then log out and back in (WSL: `wsl --shutdown` from PowerShell, reopen Ubuntu). |
<!-- /os -->
<!-- os:windows -->
| `permission denied while trying to connect to the Docker daemon socket` | your user is not in the `docker` group yet | `sudo usermod -aG docker "$USER"`, then `wsl --shutdown` from PowerShell and reopen Ubuntu. |
<!-- /os -->
<!-- os:ubuntu -->
| `permission denied while trying to connect to the Docker daemon socket` | your user is not in the `docker` group yet | `sudo usermod -aG docker "$USER"`, then log out and back in. |
<!-- /os -->
<!-- os:all -->
| `docker: command not found` | Docker is not installed, or not on `PATH` in this shell | redo the section for your OS; on Windows make sure you are in the **Ubuntu** window, not PowerShell. |
<!-- /os -->
<!-- os:windows -->
| `docker: command not found` | Docker is not installed, or you are in the wrong window | make sure you are in the **Ubuntu** window, not PowerShell; then redo section 2. |
<!-- /os -->
<!-- os:ubuntu macos -->
| `docker: command not found` | Docker is not installed, or not on `PATH` in this shell | redo the install section above; open a new terminal window afterwards. |
<!-- /os -->
<!-- os:all -->
| `docker compose` → `unknown shorthand flag` or `'compose' is not a docker command` | the Compose **plugin** is missing (you may have the old v1 `docker-compose`) | Ubuntu/WSL: `sudo apt-get install -y docker-compose-plugin`. macOS: update Docker Desktop. |
<!-- /os -->
<!-- os:ubuntu windows -->
| `docker compose` → `unknown shorthand flag` or `'compose' is not a docker command` | the Compose **plugin** is missing (you may have the old v1 `docker-compose`) | `sudo apt-get install -y docker-compose-plugin`. |
<!-- /os -->
<!-- os:macos -->
| `docker compose` → `unknown shorthand flag` or `'compose' is not a docker command` | the Compose plugin is missing (an old or partial Docker Desktop) | update Docker Desktop; the plugin ships with it. |
<!-- /os -->
| `hello-world` fails with a network/TLS error | no internet, or a corporate proxy | connect; if you are behind a proxy, configure it for Docker (ask your IT) — the course cannot run without the first pulls. |

---

## 6. Build the course image (once)

From the course folder:

```bash
cd ~/secmlops/bash-course-student
docker build -t bash-course:2.0 env/
```

**Expected:** several `[+] Building …` steps ending in a line containing
`naming to docker.io/library/bash-course:2.0`. This takes 1–3 minutes (it pulls
`ubuntu:24.04` and installs shellcheck, jq, git). Then record what *you* actually got —
never copy digests or versions from a document:

```bash
docker image inspect --format '{{index .RepoDigests 0}}' ubuntu:24.04 | tee -a env/MANIFEST.txt
docker run --rm bash-course:2.0 bash -c 'bash --version | head -1; shellcheck --version | sed -n 2p; jq --version' | tee -a env/MANIFEST.txt
```

**Expected:** a line `ubuntu@sha256:<64 hex digits>`, then one line each for bash
(`GNU bash, version 5.x`), shellcheck (`version: 0.x`) and jq (`jq-1.x`).

If the build fails on `apt-get`, it is almost always the network (proxy or a captive
portal); rerun once connected. If it fails on `useradd`, you have an unusual Docker setup —
report it with the full output.

---

## 7. Start a lab session (every time you study)

```bash
cd ~/secmlops/bash-course-student
docker run --rm -it -v "$PWD":/course -w /course bash-course:2.0
```

The prompt changes to `learner@<id>:/course$` — you are **inside** the container, in the
course folder. Your files stay <!-- os:all ubuntu macos -->on your computer<!-- /os --><!-- os:windows -->in your WSL home<!-- /os -->; the container only provides the tools.
Verify:

```bash
bash tools-check.sh        # expect the last line to begin with: ready
bash grade-all.sh          # your exercise dashboard — all red at the start, that is the plan
```

Type `exit` to leave the container. Nothing is lost: `/course` *is* your real folder.
Edit files with any editor on your computer (VS Code, nano inside the container, …) and
run the graders inside the container.
<!-- os:all -->
On Windows, open the folder in VS Code from the Ubuntu window with `code .` (installs the
WSL extension the first time) so the editor saves Linux line endings.
<!-- /os -->
<!-- os:windows -->
Open the folder in VS Code from the Ubuntu window with `code .` (installs the WSL extension
the first time) so the editor saves Linux line endings — a file saved with Windows (CRLF)
line endings shows up as `bad interpreter` or `^M` errors.
<!-- /os -->

**Module M09 and the capstone run differently.** Their scripts drive Docker itself, so
they run **on your own shell** (the one where `docker ps` works<!-- os:all windows -->; on Windows 11 that is
the Ubuntu window<!-- /os -->), not inside the course container. The first `stackctl up` builds the
program's `fraudclf-serve:m0` image from the inherited app copy
(`labs/lab9-stackctl/exercise/work/app/Dockerfile.course`) — several minutes and network
access the first time, cached afterwards — and pulls `nginx:1.27-alpine` for the gateway.
(Advanced alternative, not required: run the course container with the Docker socket
mounted, `-v /var/run/docker.sock:/var/run/docker.sock`, and the docker CLI in the image.
That grants the container full control of your daemon — effectively root on the host.)

---

## 8. No Docker? (fallback for M00–M08 only)

Modules M00–M08 need only bash ≥ 4, coreutils, awk/sed/grep and (recommended) shellcheck,
flock, jq, curl, python3 and make<!-- os:windows --> — all available in WSL 2 Ubuntu without Docker<!-- /os -->. M09 and CAP-01 need Docker; without it M09 can be read and its control logic
tested in mock mode, but the live evidence for CAP-01 cannot be produced.

<!-- os:all -->
- **Ubuntu / Debian (also WSL 2 Ubuntu):** bash 5 is already the system shell.
<!-- /os -->
<!-- os:ubuntu -->
- **Ubuntu / Debian:** bash 5 is already the system shell.
<!-- /os -->
<!-- os:windows -->
- **WSL 2 Ubuntu:** bash 5 is already the system shell.
  ```bash
  sudo apt-get update && sudo apt-get install -y shellcheck gawk jq curl python3 make
  ```
<!-- /os -->
<!-- os:macos -->
- **macOS:** do section 3 step 6 (Homebrew bash 5, shellcheck, `flock`, the GNU tools, `jq`,
  `python3`); `make` comes with the Xcode Command Line Tools (`xcode-select --install`). Run
  the labs with `bash labs/…` explicitly and check `bash --version` → `5.x`. With the GNU
  tools first on `PATH`, `tools-check.sh` reports every tool, `flock` included, so the two
  locking steps (M07 S07.5, M09 S09.5) run on the Mac itself.
<!-- /os -->
- Confirm:
  ```bash
  bash tools-check.sh
  ```
  **Expected:** every line under `== required ==` says `ok`, and the last line begins
  with `ready`.

---

## 9. V-01 — Verification task (not yet performed)

On a machine with a working daemon, from the course folder:

1. `docker build -t bash-course:2.0 env/` — record the base-image digest and tool versions as in section 6.
2. `docker run --rm -v "$PWD":/course -w /course bash-course:2.0 bash tools-check.sh` — expect the last line to begin with `ready`.
3. (Trainer bundle only) `docker run --rm -v "$PWD":/course -w /course bash-course:2.0 bash prove_all.sh` — expect `ALL GREEN`. Students run `bash grade-all.sh` instead and expect all labs listed (red until they do the work).
4. Record date, machine, OS, Docker version and the results in `env/MANIFEST.txt`.

Only after V-01 passes on a machine may the environment be described as validated. Do it
once per platform you support<!-- os:all macos --> (Ubuntu, macOS Intel, macOS Apple Silicon, WSL 2)<!-- /os --> — the
commands are identical; the base image is multi-architecture. Each platform edition of
this page carries only its own install section; the all-platform master carries all three.
