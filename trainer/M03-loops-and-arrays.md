# M03 — Loops and arrays
**FULL TRAINER EDITION · curriculum v2.0.0-draft · self-paced, no fixed duration**

> **TRAINER ONLY — about this edition.** Student text verbatim; trainer blocks inserted. IDs: S03.1–S03.4, LAB-03, A-04.
>
> **Prep (≈15 min).** `cd labs/lab3-loops-arrays/exercise && rm -rf work && bash grade.sh` → **observed** `---- lab3: 1 passed, 4 failed ----`; `GRADE_TARGET="$PWD/solution" bash grade.sh` → **observed** `---- lab3: 5 passed, 0 failed ----`; `bash labs/lab3-loops-arrays/lab.sh` → **observed** `---- lab3: 20 passed, 0 failed ----`. The grader regenerates fixtures with the course-root `seed/make_logs.sh` on every run (access.log: 140 lines, 200=85 404=10 401=40 500=5; auth.log: failed-by-IP 203.0.113.9=25, 198.51.100.23=4, 192.0.2.5=2). Any learner on a host bash 3.x (macOS) **must** use the container for this module — `declare -A` does not exist there.
>
> **Trainer effort:** prep 15 min; A-04 review ≈ 6 min per learner (grader automatic; R2 asks for an observation you should check was actually made).
>
> **Facilitator pathway (optional 45-min session).** 0–10 min: S03.1 live — run the `for line in $(…)` anti-pattern on a line with a space so the room *sees* the extra item. 10–20 min: S03.2–S03.3 self-paced; circulate on `:-0`. 20–40 min: LAB-03. 40–45 min: debrief R1 aloud.


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


> **TRAINER ONLY.** *Ask:* "What are the three pieces of `while IFS= read -r line`, and what does each protect?" *Expected:* `IFS=` keeps leading/trailing whitespace; `-r` keeps backslashes; `"$line"` (when used) keeps the value whole. *Observed demos to run live:* `printf 'a\\tb\n' | { read -r x; echo "$x"; }` → `a\tb`; without `-r` → `atb`. `printf 'one two\nthree\n' > g.txt; for l in $(cat g.txt); do echo "[$l]"; done` → `[one] [two] [three]` — three items from two lines. *Misconception:* "`cat file | while read` is the same as `while read < file`" — functionally for reading, yes, but the pipe puts the loop in a subshell (S03.4's note); prefer the redirection.

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


> **TRAINER ONLY — the index-8 trap (this is where v1 of the course had a factual error, fixed 2026-10-19).** A Combined-Log timestamp `[19/Oct/2026:06:10:00 +0000]` is **two** whitespace-separated tokens, so the status is field 9 → index 8. A learner who tests with a shortened line like `[..]` gets `status=512` and concludes the index is wrong; the index is right, their line is not. The fixture generator emits 10 whitespace-separated tokens per line (`${#parts[@]}` → `10`, observed), with the user-agent in quotes as the last. *Ask:* "What would `read -ra` do to a request path containing a space?" *Expected:* "split it — which is why `logsleuth`'s awk-based `field_status` (M05) also keys on `$9` matching three digits rather than trusting position blindly."

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


> **TRAINER ONLY — show the `set -u` abort, don't just assert it (observed).** `bash -c 'set -u; declare -A m; (( ++m[k] )); echo after'` → `m: unbound variable`, and `after` is never printed. Then `bash -c 'set -u; declare -A m; m[k]=$(( ${m[k]:-0} + 1 )); echo "ok ${m[k]}"'` → `ok 1`. This is R2's required observation — learners must *do* it, not quote it. *Misconception:* "`declare -A` is optional" — without it `n[200]` is an *indexed* array and string keys like `abc` silently become index 0; show `unset n; n[abc]=1; echo "${!n[@]}"` → `0` if you want a memorable moment. *Note on `local -A`:* the starter already declares `local -A n` inside the function — point out that `declare -A` and `local -A` are the same declaration at different scopes (M04 makes scope explicit).

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


> **TRAINER ONLY — the subshell gotcha, observed.** After the piped loop in the student demo, `echo "count after piped loop: $count"` prints `0`: the loop ran in a subshell and its `count` died with it. The exercise avoids this by reading from the file (`done < "$f"`), which keeps the loop in the current shell. If an advanced learner mentions `shopt -s lastpipe`, confirm it exists and say it is out of scope (it also requires job control off, which is the default in scripts but not at the prompt). *Pattern pitfall (H3):* `*"from $ip"*` without the trailing space also matches `203.0.113.99`; the fixture has no such IP, so the grader will not catch it — ask learners to explain the space anyway; it is the kind of silent over-match a security tool cannot afford.

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


> **TRAINER ONLY — what `lab.sh` asserts (20 checks, observed).** `for` over a list (sum 10) and C-style (`012`); `while read -r` counts 140 lines; `-r` preserves `a\tb`; `until` stops at 3; `continue` skips (`abc`); indexed array length/index/append/join (`10.0.0.1,10.0.0.2,203.0.113.9,198.51.100.7,`); `mapfile` count equals `wc -l`; associative counts 85/40/5 and **4 distinct keys**; the learner-built failed-login map (203.0.113.9 → 25, 198.51.100.23 → 4); and the real tool: `logsleuth bruteforce` names the attacker with 25 and exits **3** (over threshold) — a pipeline-friendly status that M06 formalizes.

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


> **TRAINER ONLY — complete solution (reference `solution/counters.sh`, observed 5/5):**
> ```bash
> #!/usr/bin/env bash
> # Lab 3 solution — counting with loops and associative arrays.
>
> # count_status: tally status codes (field 9) from an access log.
> count_status() {
>   local f="$1" line code c
>   local -A n
>   local -a parts
>   while IFS= read -r line; do
>     read -ra parts <<< "$line"
>     code="${parts[8]:-}"
>     [[ "$code" =~ ^[0-9]{3}$ ]] || continue
>     n["$code"]=$(( ${n["$code"]:-0} + 1 ))     # :-0 defaults an unset key under set -u
>   done < "$f"
>   for c in $(printf '%s\n' "${!n[@]}" | sort); do
>     printf '%s %s\n' "$c" "${n[$c]}"
>   done
> }
>
> # bruteforce_count: how many failed sshd logins came from <ip> in an auth log.
> bruteforce_count() {
>   local f="$1" ip="$2" line count=0
>   while IFS= read -r line; do
>     [[ "$line" == *"Failed password"*"from $ip "* ]] && count=$(( count + 1 ))
>   done < "$f"
>   printf '%s\n' "$count"
> }
> ```
> *Acceptable variations:* `(( count++ ))` passes (note `(( count++ ))` returns status 1 when `count` is 0 — harmless here because nothing tests it, but it *does* trip `set -e` when it is the last command of a function; worth one sentence); `for c in "${!n[@]}"; do …; done | sort` passes (the grader only checks `contains`); `awk`/`grep -c` one-liners pass the checks but skip the lesson — ask for the loop version, the awk version is M05's job. The unquoted `$(printf … | sort)` in the reference is safe only because keys are digit strings — say so if a learner asks why the house rule is bent here.
>
> **Grading procedure (≈6 min/learner).** 1) `GRADE_TARGET=/path/to/their/work bash labs/lab3-loops-arrays/exercise/grade.sh` → require `---- lab3: 5 passed, 0 failed ----`. 2) Reflections:
> - **R1 — Met:** names the mechanism (word splitting on IFS, plus globbing) and two concrete breakages: lines with spaces become several items; backslashes/leading whitespace/`*` are mangled or expanded. **Strong:** adds that `$(cat …)` loads the whole file into memory, or that the `while` form streams. **Not met:** "`while read` is the recommended way" with no breakage named.
> - **R2 — Met:** explains that `set -u` treats an unset array key as an unbound variable, so the first increment of a new key aborts; `:-0` substitutes 0 for a missing key; **and** reports the actual message seen (`n: unbound variable` or equivalent). **Strong:** notes the abort happens only on the *first* occurrence of each key, which is why a quick test with one line can hide the bug. **Not met:** "it's safer" / no observation reported.
>
> 3) Record `A-04 PASS` only with 5/5 and both reflections ≥ Met.
>
> **Calibration.** *R2 Met:* "Without `:-0`, `${n[$code]}` on a key that hasn't been seen is unbound; under `set -u` bash printed `n: unbound variable` and stopped before the loop finished. With `:-0` the missing key reads as 0 and the first increment gives 1." *R2 Not met:* "`:-0` sets the default to zero so the count starts at zero." (true, but no `set -u` mechanism and no observation — return with "what did bash print when you removed it?").
>
> **Model feedback (Not yet):** "`200 count is 85` got `[]`: your `count_status` printed nothing — check the second TODO; the loop counts but the print loop is still `:`." **Remediation:** S03.3 (the print loop) and S03.1. **Equivalent reassessment:** same grader; **R1'** "Why does the exercise read with `done < "$f"` rather than `cat "$f" | while …`?" (Met: the pipe runs the loop in a subshell, so counters set inside are lost) and **R2'** "Why does `count_status` skip lines whose field 9 is not three digits?" (Met: malformed lines would become bogus keys; the guard keeps the tally honest).
>
> **Evidence handling / reset:** as M01.

---

## Knowledge checks (predict, then run)

1. What does the `-r` in `read -r` prevent?
2. What does `${#arr[@]}` give?
3. What does `${!n[@]}` give for an associative array?
4. What does `mapfile -t lines < file` do?
5. In a Combined-Log line split with `read -ra parts`, which index holds the status?


> **TRAINER ONLY — answers and distractors.**
> 1. Backslash interpretation (`a\tb` → `atb` without `-r`, observed). Tempting: "raw mode disables IFS" — IFS is separate (that is `IFS=`).
> 2. The element count. Tempting: `${#arr}` — that is the length of element 0.
> 3. The keys. Tempting: `${n[@]}` — the values.
> 4. Whole file → array, one line per element, newlines stripped (`-t`); observed `3 elements`. Tempting: "reads one line" — that is `read`.
> 5. Index 8 (field 9). Tempting: index 7 — forgets the two-token timestamp.

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


> **TRAINER ONLY — end of module.** Debrief: "Which single character in `*"from $ip "*` would you most regret deleting?" (expected: the trailing space — `203.0.113.9` would match `203.0.113.99`). **Prepare M04:** nothing new to install; `logsleuth/lib/*.sh` must be present (M04's walkthrough sources `util.sh` and `parse.sh` directly). **Session close:** record A-04; collect `work/counters.sh` and `work/REFLECTION.md`.