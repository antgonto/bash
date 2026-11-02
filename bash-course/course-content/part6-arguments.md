# Part 6 — Arguments, options, and UX

> Graded by `labs/lab6-arguments/exercise/grade.sh`. Turning a script into a real
> command with options and subcommands. In this part you build logsleuth's option
> parser and its file-or-stdin reader.

**What you'll build.** In `labs/lab6-arguments/exercise/` you implement
`parse_opts` and `read_input` in `cli.sh`. First, the moves.

---

## Step 1 — Positional parameters

```bash
show() { printf 'first=%s count=%d all=[%s]\n' "$1" "$#" "$*"; }
show a "b c" d
```
```text
first=a count=3 all=[a b c d]
```

`"$@"` preserves each argument (quoted); `shift` drops `$1` and renumbers.

---

## Step 2 — `getopts` parses short options

The leading `:` in the optstring turns on *your* error handling (`:` for a missing
argument, `\?` for an unknown option):

```bash
parse() {
  local n=10 v=0 OPTIND opt
  while getopts ":n:v" opt; do
    case "$opt" in
      n)  n="$OPTARG" ;;
      v)  v=1 ;;
      :)  echo "error: -$OPTARG needs an argument" >&2; return 2 ;;
      \?) echo "error: unknown option -$OPTARG" >&2; return 2 ;;
    esac
  done
  shift $((OPTIND-1))
  echo "n=$n v=$v rest=$*"
}
parse -n 5 -v access.log
parse access.log
```
```text
n=5 v=1 rest=access.log
n=10 v=0 rest=access.log
```

This is exactly how logsleuth parses `-c -n -f -h -V`.

---

## Step 3 — File-or-stdin, and exit codes as an API

Read a named file when given, else stdin — so your tool composes in pipelines:

```bash
read_input() { if [[ $# -ge 1 ]]; then cat -- "$1"; else cat; fi; }
printf 'piped\n' | read_input
```
```text
piped
```

And give **distinct exit codes** for distinct outcomes (0 ok, 1 runtime, 2 usage)
so callers can branch — `logsleuth bruteforce … || alert`.

---

## Your exercise

Open `labs/lab6-arguments/exercise/` and read `TASK.md`. You implement:
- `parse_opts` — `getopts` for `-n N` (default 10) and `-v`, with error handling;
  prints `n=.. v=.. rest=..`.
- `read_input` — a named FILE, or stdin when omitted.

```bash
cd labs/lab6-arguments/exercise
bash grade.sh                 # seeds work/ and grades it
# ...edit work/cli.sh...
bash grade.sh                 # until: ---- lab6: N passed, 0 failed ----
```

---

## What you can do at the end of Part 6

Build a proper command: positional arguments, `getopts` options with error
handling, file-or-stdin input, and exit codes that act as an API. Your script is
now something other programs — and other people — can rely on.
