# Part 5 — The text-processing toolkit

> Graded by `labs/lab5-text-processing/exercise/grade.sh`. The pipeline that makes
> the shell uniquely good at logs. In this part you build two of logsleuth's
> reports as pipelines — the "top talkers" counter and a status-class filter.

**What you'll build.** In `labs/lab5-text-processing/exercise/` you implement
`top_ips` and `count_class` in `reports.sh`. First, the moves.

---

## Step 1 — grep, cut, awk: select and pick

```bash
printf '10.0.0.1 GET 200\n10.0.0.2 GET 404\n10.0.0.1 GET 500\n' > /tmp/ex.txt
grep -c 200 /tmp/ex.txt           # count matching lines
awk '{print $1}' /tmp/ex.txt      # pick a column (field 1)
```
```text
1
10.0.0.1
10.0.0.2
10.0.0.1
```

---

## Step 2 — The counting pipeline

`sort | uniq -c | sort -rn` is the canonical "top N". `uniq -c` collapses
**adjacent** duplicates, so the input must be **sorted** first:

```bash
awk '{print $1}' /tmp/ex.txt | sort | uniq -c | sort -rn
```
```text
      2 10.0.0.1
      1 10.0.0.2
```

Reshape it to `<ip> <count>` with a final `awk`:

```bash
awk '{print $1}' /tmp/ex.txt | sort | uniq -c | sort -rn | awk '{print $2, $1}'
```
```text
10.0.0.1 2
10.0.0.2 1
```

This single idiom answers "most frequent IP/path/status" — the backbone of
`logsleuth top`.

---

## Step 3 — awk filters and counts

`awk` filters and aggregates in one pass. Count lines whose status (a field) is in
a class:

```bash
awk '$3 ~ /^4/ {c++} END{print c+0}' /tmp/ex.txt     # how many 4xx
```
```text
1
```

In a real access log the status is field 9 (`$9`); the move is identical.

---

## Your exercise

Open `labs/lab5-text-processing/exercise/` and read `TASK.md`. The grader generates
fixture logs (top IP `10.0.0.1` = 50; 4xx = 50, 5xx = 5, 2xx = 85). You implement:
- `top_ips` — the counting pipeline, printing `<ip> <count>` most-frequent first.
- `count_class` — an `awk` filter counting a status class (`4` → 4xx).

```bash
cd labs/lab5-text-processing/exercise
bash grade.sh                 # generates fixtures, seeds work/, grades it
# ...edit work/reports.sh...
bash grade.sh                 # until: ---- lab5: N passed, 0 failed ----
```

---

## What you can do at the end of Part 5

Slice, filter, count, and transform text with grep/cut/sort/uniq/sed/awk, and wire
commands together with pipes. This is the part of shell no other language does as
well — and the two pipelines you wrote are the ones behind `logsleuth top` and
`summary`.
