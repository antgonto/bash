# Part 3 — Loops and arrays

> Graded by `labs/lab3-loops-arrays/exercise/grade.sh`. Reading input correctly,
> and counting with arrays — the core skill of log analysis. In this part you
> build logsleuth's counting core: status-code tallies and the per-IP brute-force
> counter.

**What you'll build.** In `labs/lab3-loops-arrays/exercise/` you implement
`count_status` and `bruteforce_count` in `counters.sh`. First, the moves.

---

## Step 1 — `while read -r` is the only correct way to read lines

```bash
printf 'one\ntwo\nthree\n' | while IFS= read -r line; do
  printf 'got: %s\n' "$line"
done
```
```text
got: one
got: two
got: three
```

- `-r` keeps backslashes literal, `IFS=` keeps leading/trailing whitespace, and
  you quote `"$line"`.
- Never `for line in $(cat file)` — it splits on spaces and globs.

---

## Step 2 — Split a line into fields

```bash
line='10.0.0.1 - - [19/Oct/2026:06:10:00 +0000] "GET /x HTTP/1.1" 200 512'
read -ra parts <<< "$line"
echo "ip=${parts[0]} status=${parts[8]}"     # field 9 is index 8
```
```text
ip=10.0.0.1 status=200
```

---

## Step 3 — Count by key with an associative array

An associative array is a map — the heart of "how many of each?":

```bash
declare -A n
for code in 200 200 404 200 500; do
  n["$code"]=$(( ${n["$code"]:-0} + 1 ))     # :-0 defaults an unset key under set -u
done
for c in "${!n[@]}"; do printf '%s %s\n' "$c" "${n[$c]}"; done | sort
```
```text
200 3
404 1
500 1
```

A bare `(( ++n[k] ))` on an unset key aborts under `set -u`; the `:-0` form is why
logsleuth can scan an attacker in one pass.

---

## Step 4 — The brute-force idea

Counting failed logins per IP is the same move over an auth log — match the
"Failed password … from `<ip>`" lines and tally. That counter *is* logsleuth's
`cmd_bruteforce`.

---

## Your exercise

Open `labs/lab3-loops-arrays/exercise/` and read `TASK.md`. The grader generates
deterministic fixture logs (200=85, 401=40, 500=5; IP `203.0.113.9` has 25 failed
logins). You implement:
- `count_status` — tally status codes into an associative array, printing
  `<code> <count>` sorted by code.
- `bruteforce_count` — count failed logins from a given IP.

```bash
cd labs/lab3-loops-arrays/exercise
bash grade.sh                 # generates fixtures, seeds work/, grades it
# ...edit work/counters.sh...
bash grade.sh                 # until: ---- lab3: N passed, 0 failed ----
```

---

## What you can do at the end of Part 3

Iterate anything, read files the one correct way, and count by key with
associative arrays. You can now answer "how many of each?" about any log — and the
counter you wrote is exactly how logsleuth finds a brute-force source in one pass.
