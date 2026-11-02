# Part 2 — Conditionals

> Graded by `labs/lab2-conditionals/exercise/grade.sh`. Branching, the right test
> syntax, and `case`. In this part you build logsleuth's two gatekeepers: the
> check that a log is readable before touching it, and the router that turns a
> subcommand name into the right handler.

**What you'll build.** In `labs/lab2-conditionals/exercise/` you implement
`validate_log` and `route` in `router.sh`. First, the moves.

---

## Step 1 — `if` tests a command, not a boolean

`if` runs the `then` branch when a *command* succeeds (exit 0):

```bash
if grep -q root /etc/passwd; then echo found; else echo missing; fi
```
```text
found
```

`grep -q`, `test`, and `[[ … ]]` are just commands that return 0/1. That is the
whole model.

---

## Step 2 — Prefer `[[ ]]`, and the tests you need

`[[ … ]]` is a bash keyword that does **not** word-split or glob its operands, so
an empty or spaced variable can't break its syntax:

```bash
f=/etc/hostname
[[ -r "$f" ]] && echo readable        # -r readable, -f file, -d dir, -s non-empty
[[ "$f" == *hostname ]] && echo "matches a glob"
[[ "404" =~ ^[0-9]{3}$ ]] && echo "matches a regex"
```
```text
readable
matches a glob
matches a regex
```

logsleuth runs `[[ -r "$f" ]]` before reading a log, and dies with a clear
message if it can't.

---

## Step 3 — `case` dispatches on a value

`case` matches globs top to bottom; `*` is the catch-all. This is how logsleuth
turns the first argument into the right function:

```bash
route() {
  case "$1" in
    summary|top|errors) echo valid ;;
    brute*)             echo brute ;;
    *)                  echo unknown ;;
  esac
}
route summary; route bruteforce; route frobnicate
```
```text
valid
brute
unknown
```

---

## Step 4 — Guard, then act

A readable-or-die guard, and distinct exit codes, are how a tool refuses bad input
cleanly:

```bash
validate_log() {
  local f="$1"
  if [[ -r "$f" ]]; then return 0
  else printf 'cannot read log file: %s\n' "$f" >&2; return 1
  fi
}
validate_log /etc/hostname && echo "ok"
validate_log /nope.log || echo "refused (exit $?)"
```
```text
ok
cannot read log file: /nope.log
refused (exit 1)
```

---

## Your exercise

Open `labs/lab2-conditionals/exercise/` and read `TASK.md`. You implement:
- `validate_log` — succeed if the file is readable, else print
  `cannot read log file: <path>` and fail.
- `route` — map `summary|top|errors` → `valid`, `brute*` → `brute`, else `unknown`.

```bash
cd labs/lab2-conditionals/exercise
bash grade.sh                 # seeds work/ and grades it
# ...edit work/router.sh...
bash grade.sh                 # until: ---- lab2: N passed, 0 failed ----
```

---

## What you can do at the end of Part 2

Branch on command status, test strings/numbers/files with the safe `[[ ]]`,
express guards with `&&`/`||`, and dispatch with `case`. You just wrote logsleuth's
input validation and subcommand routing — the control flow every real script is
built from.
