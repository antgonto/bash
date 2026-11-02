# Part 1 — Variables, quoting, and parameter expansion

> Graded by `labs/lab1-variables/exercise/grade.sh`. The single biggest source of
> bash bugs is an unquoted variable; the single biggest source of clean bash is
> parameter expansion. In this part you build three helpers logsleuth really uses
> — turn a log path into a name, compose a report filename, and read a config line.

**What you'll build.** In `labs/lab1-variables/exercise/` you implement `stem`,
`report_name`, and `parse_kv` in `params.sh`, and a grader turns red to green as
you go. First, the moves.

---

## Step 1 — Assign, expand, and quote

Try each line in a terminal:

```bash
name=logsleuth              # assignment: NO spaces around =
echo "$name"                # expansion: always quoted
now="$(date +%F)"           # command substitution: capture output
echo "report for $name on $now"
```
```text
logsleuth
report for logsleuth on 2026-10-16
```

**The #1 footgun.** An *unquoted* `$var` is split on whitespace and expanded as a
glob. Prove it to yourself:

```bash
path="my logs/access.log"
printf '[%s]\n' $path        # unquoted: TWO arguments
printf '[%s]\n' "$path"      # quoted: one
```
```text
[my]
[logs/access.log]
[my logs/access.log]
```

Always write `"$var"`. logsleuth quotes every expansion, which is why it analyzes
a log file whose name contains a space without missing a beat.

---

## Step 2 — Parameter expansion: defaults, length, case

Parameter expansion transforms a value *without* calling another program:

```bash
x=""
echo "${x:-10}"      # default when unset/empty  -> how logsleuth defaults TOP_N
y=Error
echo "${#y}"         # length
echo "${y,,}"        # lower-case
```
```text
10
5
error
```

---

## Step 3 — Strip prefixes and suffixes (build a name)

The `#`/`##` (front) and `%`/`%%` (back) operators slice strings — no
`basename`/`dirname` needed:

```bash
path=/var/log/nginx/access.log
base="${path##*/}"       # strip the longest leading */  -> basename
echo "$base"
echo "${base%.log}"      # strip a trailing .log         -> the stem
```
```text
access.log
access
```

Compose a report filename from the parts — exactly what a reporting tool does:

```bash
stem=access; date=2026-10-16
printf 'report-%s-%s.txt\n' "$stem" "$date"
```
```text
report-access-2026-10-16.txt
```

---

## Step 4 — `read` and arithmetic (parse a config line)

`read` splits input into variables; a bare `read` trims surrounding whitespace:

```bash
IFS='=' read -r k v <<< "top_n = 25"    # split on =
read -r key   <<< "$k"                    # trim
read -r value <<< "$v"
printf 'key=[%s] value=[%s]\n' "$key" "$value"
echo "$(( value * 2 ))"                    # integer arithmetic
```
```text
key=[top_n] value=[25]
50
```

This is precisely how logsleuth reads a `key = value` config line — as **data**,
never by `source`-ing it.

---

## Your exercise

Open `labs/lab1-variables/exercise/` and read `TASK.md`. You implement:
- `stem` — `/var/log/nginx/access.log` → `access`
- `report_name` — `report-access-2026-10-16.txt`
- `parse_kv` — `top_n = 25` → `KEY=top_n`, `VALUE=25`

```bash
cd labs/lab1-variables/exercise
bash grade.sh                 # seeds work/ and grades it (all FAIL at first)
# ...edit work/params.sh, completing each # TODO...
bash grade.sh                 # until: ---- lab1: N passed, 0 failed ----
```

The reference answer is in `solution/params.sh` — peek only once you're green or stuck.

---

## What you can do at the end of Part 1

Store and transform data safely: quote everything, default the unset, slice and
rename with parameter expansion, compute with `$(( ))`, and parse `key = value`
input. The three helpers you wrote are real pieces of logsleuth's config and
reporting — the bugs this prevents are the ones that bite every bash beginner.
