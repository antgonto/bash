# Part 0 — Your first script

> Graded by `labs/lab0-first-script/lab.sh`. This part is a hands-on build: you
> start from an empty file and finish with a small, **real command-line script
> you can keep and run from anywhere**. Along the way you meet everything a
> script needs *before* it has logic — shebang, the execute bit, exit codes,
> `printf`, strict mode, and shellcheck.

**What you'll build.** `greet` — a tiny but genuinely runnable CLI that prints a
greeting, takes an optional name, defaults sensibly, is strict-mode safe, and is
lint-clean. It is deliberately small: Part 0 is about the *frame* every script
shares. Parts 1+ pour real logic into that frame as you build the course
project, `logsleuth`.

**Before you start.** You need only `bash` (≥ 4), a terminal, and a text editor;
`shellcheck` is recommended (Step 6). Unzip the course bundle, then make a
scratch directory to work in:

```bash
mkdir -p ~/bash-course-work/lab0 && cd ~/bash-course-work/lab0
```

Every step is the same loop: **edit the file → run it → read the exact output →
understand why.** Type the scripts yourself; that is the point.

---

## Step 1 — A file, a shebang, and the execute bit

A shell script is a plain text file whose first line, the **shebang**, names the
interpreter that should run it. Create a file named `greet` with exactly this:

```bash
#!/usr/bin/env bash
echo "hello"
```

Run it by handing the file to bash:

```bash
bash greet
```
```text
hello
```

To run it as a command (`./greet`), the file needs the **execute bit**:

```bash
chmod +x greet
./greet
```
```text
hello
```

**Why.** `#!/usr/bin/env bash` tells the OS to run the file with the `bash` found
on your `$PATH` — portable across Linux and macOS. `bash greet` ignores the
execute bit; `./greet` requires it. From here on, `./greet` works.

---

## Step 2 — Exact output with `printf`

`echo` behaves differently across shells (flags, backslashes). `printf` is
precise and portable. Change the body to:

```bash
#!/usr/bin/env bash
printf 'Hello, world!\n'
```
```bash
./greet
```
```text
Hello, world!
```

**Why.** `printf 'FORMAT' args` places text exactly and adds a newline only where
you write `\n`. Use `printf` whenever output format matters — which, for a tool
other programs read, is always.

---

## Step 3 — Take an argument, with a sensible default

A script's arguments arrive as `$1`, `$2`, …. Use a default so the script still
works with no argument:

```bash
#!/usr/bin/env bash
name="${1:-world}"
printf 'Hello, %s!\n' "$name"
```
```bash
./greet            # no argument -> the default
./greet Antonio    # one argument -> uses it
```
```text
Hello, world!
Hello, Antonio!
```

**Why.** `${1:-world}` means "use `$1`, or `world` if it is unset or empty." `%s`
drops the value in exactly where you put it. (Parameter expansion is the whole of
Part 1 — this is a first taste.)

---

## Step 4 — Strict mode: the house header

Every script in this course starts with the same safety header. Add it:

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

name="${1:-world}"
printf 'Hello, %s!\n' "$name"
```
```bash
./greet Antonio
```
```text
Hello, Antonio!
```

**Why each flag.**
- `-e` — exit the moment a command fails, instead of blundering on.
- `-u` — using an **unset** variable is an error, not a silent empty string
  (catches typos like `$naem`).
- `pipefail` — a pipeline fails if *any* stage fails, not only the last.
- `IFS=$'\n\t'` — split words on newlines and tabs, not spaces; safer for data
  containing spaces.

Your script prints the same line as before — strict mode changes nothing when the
script is correct. Its job is to make an *incorrect* script fail loudly instead of
silently. (Part 7 covers the two places strict mode surprises people.)

---

## Step 5 — Exit codes: what your script returns

Every command reports success through an **exit code**: `0` means success,
non-zero means failure. Your shell keeps the last one in `$?`:

```bash
./greet >/dev/null; echo "exit code: $?"
```
```text
exit code: 0
```

Exit codes are how scripts chain and how other programs consume yours:

```bash
./greet >/dev/null && echo "it worked"   # && runs next only on SUCCESS
false || echo "recovering"               # || runs next only on FAILURE
```
```text
it worked
recovering
```

**Why it matters.** Later, `logsleuth` returns *distinct* codes — `0` ok, `1`
runtime error, `2` usage error, `3` "brute force found" — so a pipeline can branch
on the outcome: `logsleuth bruteforce auth.log || alert`. A script's exit code is
its API.

---

## Step 6 — Lint it with shellcheck

`shellcheck` catches the real mistakes bash lets you make — unquoted variables,
useless `cat`, misused tests — before they ever bite. A clean script says nothing:

```bash
shellcheck greet
```
```text
(no output; exit status 0 — clean)
```

See what it catches. Temporarily remove the quotes around `"$name"` (make it
`$name`) and re-run:

```bash
shellcheck greet
```
```text
In greet line 6:
printf 'Hello, %s!\n' $name
                      ^---^ SC2086 (info): Double quote to prevent globbing and word splitting.

Did you mean:
printf 'Hello, %s!\n' "$name"
```

Put the quotes back. A clean `shellcheck` run is the bar every script in this
course meets.

*(No shellcheck? `sudo apt install shellcheck` or `brew install shellcheck`, or
skip this step — the rest of the course still runs.)*

---

## Step 7 — Keep it: a usable script on your PATH

`greet` is finished and genuinely usable. Put it somewhere on your `$PATH` and
call it from anywhere:

```bash
mkdir -p ~/.local/bin
cp greet ~/.local/bin/greet
# make sure ~/.local/bin is on your PATH (most shells already have it):
#   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
greet "Cherokee Nation"
```
```text
Hello, Cherokee Nation!
```

You just wrote, hardened, linted, and installed a command-line tool. That is the
full life of every script — the only thing Parts 1–8 add is what goes *between*
the header and the output.

---

## Run the autograder

The course proves each lesson with a script you run yourself. From the unzipped
bundle's root:

```bash
cd bash-course
bash labs/lab0-first-script/lab.sh
```

It replays every claim above against a fresh script and the `logsleuth` skeleton,
printing a section header, one line per check, and a summary:

```text
== a script is text + a shebang + the execute bit ==
  PASS: the shebang names the interpreter
  PASS: run with 'bash hello.sh'
  PASS: an argument changes the output
  PASS: the execute bit is set (so ./hello.sh would work on a normal FS)
== exit codes are a script's return value: 0 = success, non-zero = failure ==
  PASS: true -> $? is 0
  ...
---- lab0: 19 passed, 0 failed ----
```

A `PASS:` is one verified claim; a `FAIL:` prints what was expected versus what
happened. `0 failed` in the summary means the whole part checks out. Run the
entire course at once with `bash prove_all.sh` (expect `ALL GREEN`).

---

## How this becomes `logsleuth`

The course project is already in the bundle under `logsleuth/`. Its entry point is
a real script built on the exact frame you just learned — open it and run it:

```bash
head -6 logsleuth/bin/logsleuth      # same shebang + strict-mode header as yours
bash logsleuth/bin/logsleuth version
bash logsleuth/bin/logsleuth help
```
```text
#!/usr/bin/env bash
# logsleuth — analyze web access logs and sshd auth logs.
# ...
set -euo pipefail

logsleuth 1.0.0
logsleuth 1.0.0 — analyze access and auth logs

usage: logsleuth [options] <command> [FILE]
  ...
```

Same shebang, same `set -euo pipefail`, same exit-code discipline — scaled up with
the logic you build across Parts 1–8.

---

## What you can do at the end of Part 0

Write a script from an empty file, run it two ways, give it exact output and an
argument, harden it with strict mode, reason about its exit code, lint it clean,
and install it on your PATH. You have a **usable script in hand** and the frame
every later lab fills with real logic.
