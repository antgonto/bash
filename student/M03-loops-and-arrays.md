# M03 — Loops and arrays
**Student Edition · curriculum v2.0.0-draft · self-paced, no fixed duration**

**Outcome LO-04.** You can read a file line by line the one correct way, split a
line into fields, and count "how many of each" with an associative array — the
core move of log analysis.

**What you'll build.** `logsleuth`'s counting core — `count_status` and
`bruteforce_count` — in `labs/lab3-loops-arrays/exercise/` (graded as A-04).

**Prerequisite check.** A-03 passed. You use S01.2 (quoting) and S02.2 (`[[ =~ ]]`).
This module needs **bash ≥ 4** (associative arrays): the container has 5.x; macOS's
built-in 3.2 will not work — use the container.

---

## Activity context for S03.1–S03.4

| Field | Value |
|---|---|
| Execution context | Inside the course container (or a bash ≥ 4 fallback shell), at the prompt |
| Starting state | `bash tools-check.sh` reports ready; `bash --version` shows 4.x or 5.x |
| Validation status | Every expected output in S03.1–S03.4 was **observed** in the authoring environment (bash 5.2.21, 2026-10-19) |

### S03.1 — `while read -r` is the one correct way to read lines
- **Purpose.** Read input line by line without corrupting it. (SK-04)
- **Exact action.**
  ```bash
  printf 'one\ntwo\nthree\n' | while IFS= read -r line; do
    printf 'got: %s\n' "$line"
  done
  ```
- **Expected observation (observed).**
  ```text
  got: one
  got: two
  got: three
  ```
- **Verification.** Three lines, in order.
- **Recovery.** Only `got: one` → you used `read` without a loop, or the pipe is missing. If you tried `for line in $(…)` instead, it *also* prints three lines here — that is exactly why it is dangerous: it splits on spaces as well as newlines, so `printf 'one two\nthree\n'` gives **three** items instead of two (observed). This step teaches you never to use it for lines.
- **Evidence / next state.** **Why each part:** `-r` keeps backslashes literal (without it `a\tb` becomes `atb`, observed); `IFS=` preserves leading/trailing whitespace; `"$line"` is quoted. Never `for line in $(cat file)`.

### S03.2 — Split a line into fields
- **Purpose.** Pull the IP and the status out of a real web-log line.
- **Exact action.**
  ```bash
  line='10.0.0.1 - - [19/Oct/2026:06:10:00 +0000] "GET /x HTTP/1.1" 200 512'
  read -ra parts <<< "$line"
  echo "ip=${parts[0]} status=${parts[8]}"     # field 9 is index 8
  ```
- **Expected observation (observed).** `ip=10.0.0.1 status=200`
- **Verification.** Exactly that line.
- **Recovery.** `status=512` → your line has a one-token timestamp (e.g. `[..]`); a real Combined-Log timestamp is **two** whitespace-separated tokens (`[date` and `+0000]`), which is why the status is index 8. Use the line exactly as shown. `status=` empty → `read -ra` missing the `-a`.
- **Evidence / next state.** **Why:** `read -ra parts` splits one line into an indexed array on whitespace; `${parts[8]}` is the ninth field. The fixture logs the grader generates have exactly this shape.

### S03.3 — Count by key with an associative array
- **Purpose.** Tally occurrences — the heart of "how many of each?"
- **Exact action.**
  ```bash
  declare -A n
  for code in 200 200 404 200 500; do
    n["$code"]=$(( ${n["$code"]:-0} + 1 ))     # :-0 defaults an unset key
  done
  for c in "${!n[@]}"; do printf '%s %s\n' "$c" "${n[$c]}"; done | sort
  ```
- **Expected observation (observed).**
  ```text
  200 3
  404 1
  500 1
  ```
- **Verification.** Three lines, sorted by code.
- **Recovery.** `declare: -A: invalid option` → bash 3.x; use the container. Counts all `1` → you assigned `=1` instead of adding; copy the `$(( … + 1 ))` line exactly.
- **Evidence / next state.** **Why `:-0`:** under `set -u` (your house header), a bare `(( ++n[k] ))` on a key that does not exist yet aborts with `n: unbound variable` (observed); `${n["$code"]:-0}` reads 0 for a new key. `${!n[@]}` lists the keys; `${#n[@]}` counts them.

### S03.4 — The brute-force idea
- **Purpose.** Apply the same loop to an auth log: count failed logins per attacker.
- **Exact action.** Simulate three auth lines and count the ones from one IP:
  ```bash
  ip=203.0.113.9; count=0
  printf 'Failed password for root from 203.0.113.9 port 22\nAccepted password for ana from 10.0.0.5 port 22\nFailed password for root from 203.0.113.9 port 23\n' |
  while IFS= read -r line; do
    [[ "$line" == *"Failed password"*"from $ip "* ]] && count=$(( count + 1 ))
    echo "$count"
  done | tail -1
  ```
- **Expected observation (observed).** `2`
- **Verification.** The single number `2`.
- **Recovery.** `0` → the pattern is quoted as one string; keep the `*` globs **outside** the quotes as shown. (Note: a counter updated inside a *piped* `while` lives in a subshell and is lost after the loop — that is why this demo prints inside the loop; the exercise reads from a file with `< "$f"` instead, which keeps the count.)
- **Evidence / next state.** That counter *is* `logsleuth`'s `cmd_bruteforce`. The exercise does it on a real fixture file.

---

## Worked demonstration (10 min)

```bash
cd /course
bash labs/lab3-loops-arrays/lab.sh
```
**Expected observation (observed).** `---- lab3: 20 passed, 0 failed ----`. It runs
`for` over lists and C-style ranges, counts all 140 fixture lines with
`while read -r`, shows `-r` preserving a backslash, exercises `until`, `break`
and `continue`, indexed arrays and `mapfile`, tallies status codes into a map
(200=85, 404=10, 401=40, 500=5 — four keys), builds the per-IP failed-login
counter (203.0.113.9 → 25, 198.51.100.23 → 4), and confirms `logsleuth bruteforce`
reports the same attacker and count and exits 3.

---

## LAB-03 — Your exercise (graded as A-04) — 45 min

| Field | Value |
|---|---|
| Location | `labs/lab3-loops-arrays/exercise/` (read `TASK.md`) |
| Starting assets | `starter/counters.sh` (two functions with `# TODO`s), `grade.sh` — which **generates deterministic fixture logs** on every run via the course's `seed/make_logs.sh` (never edit that file) |
| Allowed resources | This module, documentation, AI assistance (disclosed); **not** `solution/` |
| Deliverables | `work/counters.sh` passing the grader; `work/REFLECTION.md` with R1 and R2 |
| Acceptance | `bash grade.sh` ends `---- lab3: 5 passed, 0 failed ----`; both reflections present |

**Procedure.**
1. `cd labs/lab3-loops-arrays/exercise && bash grade.sh`. **Observed on the starter:** `---- lab3: 1 passed, 4 failed ----` (the stub's `0` happens to be right for the innocent IP).
2. Edit `work/counters.sh`:
   - `count_status`: `while IFS= read -r line; do read -ra parts <<< "$line"; code="${parts[8]:-}"; [[ "$code" =~ ^[0-9]{3}$ ]] || continue; n["$code"]=$(( ${n["$code"]:-0} + 1 )); done < "$f"`, then print `"$c ${n[$c]}"` for each key, sorted (S03.1–S03.3).
   - `bruteforce_count`: loop the auth log with `while IFS= read -r line; do … done < "$f"` and count lines matching `*"Failed password"*"from $ip "*` (S03.4).
3. Re-run until **`---- lab3: 5 passed, 0 failed ----`** (observed with the reference). Checks: `200 85`, `401 40`, `500 5` present in `count_status` output; `bruteforce_count … 203.0.113.9` = `25`; an innocent IP = `0`.
4. `work/REFLECTION.md`:
   - **R1.** Why `while IFS= read -r line … done < "$f"` rather than `for line in $(cat "$f")`? Name two things the `for` version breaks.
   - **R2.** Why does the counter use `${n["$code"]:-0}`? Test what happens under `set -u` without it, and describe what you saw.

**Learner-visible rubric (A-04).** *Pass* = `0 failed` **and** both reflections name the mechanism and (for R2) report an actual observation. Unlimited attempts.

**Hints.** H1: `count_status` must *skip* lines whose field 9 is not three digits (the `=~` guard). H2: print `"${parts[8]}"` for the first line to see what you are counting. H3: the space after `$ip` in the pattern matters — `from 203.0.113.9 ` must not also match `203.0.113.99`.

**Reset.** `rm -rf work && bash grade.sh`.

---

## Knowledge checks (predict, then run)

1. What does the `-r` in `read -r` prevent?
2. What does `${#arr[@]}` give?
3. What does `${!n[@]}` give for an associative array?
4. What does `mapfile -t lines < file` do?
5. In a Combined-Log line split with `read -ra parts`, which index holds the status?

---

## In the SecMLOps Program
`ci/sarif_gate.sh` is a `for f in "$@"` loop that sums `total=$((total+n))` over SARIF files — S03.1 and S01.5 in six lines, and the reason `"$@"` is quoted there is M01's. `ci/validate_unauth.sh` loops `for s in nuclei-unauth.sarif testssl.sarif; do [ -f "$s" ] && … done`. The associative array you built for failed logins per IP is the structure behind every "count per key" report you will write about pipeline findings; the `while read -r` loop is how Course 1's `scripts/replica-check.sh` compares two tool lists line by line (via `diff`).

---

## Recap and transfer
Read lines the one correct way, split fields, count by key. **Transfer:** M05 does
the same counting with `sort | uniq -c` pipelines — and you will be able to say
when each approach is right; M09's `stackctl status` reads `docker compose ps`
output one line at a time with exactly this loop.

---

## Self-check answers

1. Backslash interpretation — without `-r`, `a\tb` is read as `atb` (observed).
2. The number of elements.
3. The keys (as opposed to `${n[@]}`, the values).
4. Reads the whole file into the array `lines`, one line per element, stripping newlines (`-t`); observed: 3 lines → `3 elements`.
5. Index 8 (the ninth field) — the timestamp occupies two fields, which is why the status is not index 7.
