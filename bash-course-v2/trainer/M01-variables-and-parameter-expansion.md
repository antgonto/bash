# M01 — Variables, quoting, and parameter expansion
**FULL TRAINER EDITION · curriculum v2.0.0-draft · self-paced, no fixed duration**

> **TRAINER ONLY — about this edition.** Student text reproduced verbatim; trainer material in these blocks. IDs shared: S01.1–S01.7, LAB-01, A-02.
>
> **Prep (≈20 min per cohort).** 1) Rehearse the exercise: `cd labs/lab1-variables/exercise && rm -rf work && bash grade.sh` → **observed** `---- lab1: 0 passed, 7 failed ----`; `GRADE_TARGET="$PWD/solution" bash grade.sh` → **observed** `---- lab1: 7 passed, 0 failed ----`. 2) Run the walkthrough `bash labs/lab1-variables/lab.sh` → **observed** `---- lab1: 24 passed, 0 failed ----`. 3) Re-check S01.3 on any macOS learner machine that is *not* using the container: `${y,,}` needs bash ≥ 4.
>
> **Trainer effort:** prep 20 min; A-02 review ≈ 5 min per learner (grader automatic; two reflections read by a human).
>
> **Facilitator pathway (optional 45-min live session).** 0–10 min: S01.2 live — make the split happen, then quote it. 10–25 min: learners do S01.3–S01.6; circulate on `#` vs `##` confusion. 25–40 min: LAB-01. 40–45 min: debrief R2 aloud; the expected answer is under LAB-01 below.


**Outcome LO-02.** You can store and transform data safely: quote every expansion,
default the unset, slice and rename with parameter expansion, compute with
`$(( ))`, and parse a `key = value` line — and explain why each move is safe.

**What you'll build.** Three helpers `logsleuth` really uses — `stem`,
`report_name`, `parse_kv` — in `labs/lab1-variables/exercise/` (graded as A-02).

**Prerequisite check.** M00 complete: `greet` passes its grader (`A-01`). You
reference nothing from M00 beyond S00.6 (`${1:-world}`) and S00.9 (quoting).

---

## Activity context for S01.1–S01.7

| Field | Value |
|---|---|
| Execution context | Inside the course container (or fallback shell), any directory — these are one-line experiments at the prompt; `mkdir -p ~/bash-course-work/lab1 && cd ~/bash-course-work/lab1` if you want a scratch folder |
| Starting state | `bash tools-check.sh` reports ready (S00.3) |
| Validation status | Every expected output in S01.1–S01.7 was **observed** in the authoring environment (bash 5.2.21, 2026-10-19) |

Type each block at the prompt, press Enter, and read the output before moving on.

### S01.1 — Assign, expand, capture
- **Purpose.** Learn the three forms you will use in every script: assignment, expansion, and command substitution. (SK-02)
- **Exact action.**
  ```bash
  name=logsleuth              # assignment: NO spaces around =
  echo "$name"                # expansion: always quoted
  now="$(date +%F)"           # command substitution: capture a command's output
  echo "report for $name on $now"
  ```
- **Expected observation (observed; the date is yours).**
  ```text
  logsleuth
  report for logsleuth on 2026-10-19
  ```
- **Verification.** The second line contains your name variable and today's date.
- **Recovery.** `name: command not found` → you wrote `name = logsleuth` with spaces; bash ran a command called `name`. Remove the spaces. Empty first line → you typed `echo $Name` (case matters).
- **Evidence / next state.** You can set, use, and capture. **Why:** `$(…)` runs the command and substitutes its output; quoting the result keeps it one word.


> **TRAINER ONLY.** *Ask:* "Why no spaces around `=`?" *Expected:* "because bash would treat `name` as a command and `=` as its first argument" (observed: `name: command not found`, exit 127). *Misconception:* `$(…)` and backticks are different features — they are the same feature; teach `$(…)` only (it nests and is readable). *Intervene* when a learner writes `now=$(date +%F)` unquoted and it works here: say plainly that it works *today* because the output has no spaces, and the course quotes it anyway so the habit holds when output does.

### S01.2 — Quote every expansion (the #1 bug)
- **Purpose.** See word splitting happen, then prevent it.
- **Exact action.**
  ```bash
  path="my logs/access.log"
  printf '[%s]\n' $path        # unquoted
  printf '[%s]\n' "$path"      # quoted
  ```
- **Expected observation (observed, default IFS at the prompt).**
  ```text
  [my]
  [logs/access.log]
  [my logs/access.log]
  ```
- **Verification.** Three lines: the unquoted form produced **two** arguments, the quoted form one.
- **Recovery.** Only one line from the first `printf` → your shell has a non-default `IFS` (e.g., a script with `IFS=$'\n\t'`); run `unset IFS` for this experiment, or accept that spaces are not split there — tabs/newlines and `*` still are. No `[`…`]` at all → the format string lost its quotes.
- **Evidence / next state.** You have *watched* an unquoted expansion break. **Why:** an unquoted `$var` is split on the characters in `IFS` and expanded as a glob; `"$var"` is handed over as exactly one argument. `logsleuth` quotes every expansion, which is why it can analyze a file whose name contains a space.


> **TRAINER ONLY — the IFS nuance (observed 2026-10-18).** At the interactive prompt (default `IFS`) a space splits, which is what learners see here. Inside a script with the house header `IFS=$'\n\t'`, a space does **not** split, a tab does, and `*` still globs into filenames. If a learner tested S01.2 inside a script with the header and got one `[my logs/access.log]`, they did nothing wrong — use it to teach: "IFS decides *which characters* split; quoting is what makes you safe regardless." Second demo worth doing live: `touch a.txt b.txt; v='*'; printf '[%s]\n' $v` prints one line per file (globbing), `printf '[%s]\n' "$v"` prints `[*]`.

### S01.3 — Parameter expansion: defaults, length, case
- **Purpose.** Transform values without calling another program.
- **Exact action.**
  ```bash
  x=""
  echo "${x:-10}"      # default when unset OR empty
  y=Error
  echo "${#y}"         # length
  echo "${y,,}"        # lower-case (bash 4+)
  h=3f786850e387550fdab836ed7e6dc881
  echo "${h:0:2}/${h:2}"   # substring: offset 0 length 2, then from offset 2
  ```
- **Expected observation (observed).**
  ```text
  10
  5
  error
  3f/786850e387550fdab836ed7e6dc881
  ```
- **Verification.** Exactly those four lines.
- **Recovery.** `bad substitution` on the `${y,,}` line → bash 3.x (macOS default); use the container, or `brew install bash` (the substring line works on any bash).
- **Evidence / next state.** `${x:-10}` is how `logsleuth` defaults `TOP_N`. **Why the colon:** `:-` treats *empty* like unset; `${x-10}` would keep an empty value. **The substring form** `${var:offset:length}` is how Course 2 Lab 3.1 turns a DVC content hash into the cache path it lives at — `s3://ml-data/files/md5/${HASH:0:2}/${HASH:2}` — the first two hex characters become the directory, the rest the file name.


> **TRAINER ONLY.** *Demonstrate the colon:* `x=""; echo "${x-10}"` prints an empty line (value kept), `echo "${x:-10}"` prints `10`. This is knowledge check 5 and reflection R1. *Misconception:* `${#y}` counts bytes/characters — for ASCII they coincide; do not open the Unicode door here. *Grading relevance:* none directly; R1 depends on it.

### S01.4 — Strip prefixes and suffixes: build a name
- **Purpose.** Slice a path into a clean name — no `basename`/`dirname` processes needed.
- **Exact action.**
  ```bash
  path=/var/log/nginx/access.log
  base="${path##*/}"       # strip the LONGEST leading */  -> basename
  echo "$base"
  echo "${base%.log}"      # strip a trailing .log         -> the stem
  ```
- **Expected observation (observed).**
  ```text
  access.log
  access
  ```
- **Verification.** Two lines as shown.
- **Recovery.** `var/log/nginx/access.log` instead of `access.log` → you used one `#` (shortest match, strips only the leading `/`); use `##`. `access.log` on the second line → you wrote `%.log` against `$path` instead of `$base`, or the suffix doesn't match (case).
- **Evidence / next state.** You have `stem` in your hands. **Why:** `#`/`##` cut from the front (shortest/longest), `%`/`%%` from the back.


> **TRAINER ONLY.** *Demonstrate `#` vs `##`* (observed): `path=/var/log/x.log; echo "${path#*/}"` → `var/log/x.log` (shortest: only the leading `/`); `echo "${path##*/}"` → `x.log` (longest). Learners who write `#` get a "basename" that is still a path — the grader's `stem` checks catch it (`expected [access], got [var/log/nginx/access]`). *Ask:* "Which end does `%` cut from?" *Expected:* "the end" — `%` looks like a trailing marker; `#` like a leading one (a mnemonic, not a rule).

### S01.5 — Compose a report filename
- **Purpose.** Put parts together with `printf` into exactly the name a reporting tool emits.
- **Exact action.**
  ```bash
  stem=access; date=2026-10-16
  printf 'report-%s-%s.txt\n' "$stem" "$date"
  ```
- **Expected observation (observed).** `report-access-2026-10-16.txt`
- **Verification.** Exactly that line.
- **Recovery.** `report-%s-%s.txt` printed literally → arguments missing or the format is in double quotes with a stray backslash; copy the line exactly.
- **Evidence / next state.** `report_name` is `stem` + this `printf`.


> **TRAINER ONLY.** Small but important: `printf` *reuses* its format for extra arguments (observed in M00 S00.9's split demo). If a learner passes three arguments to a two-`%s` format they get a second, partial line — a useful way to show that arguments and format must match. *Grading relevance:* `report_name` check expects exactly `report-access-2026-10-16.txt`.

### S01.6 — `read` and arithmetic: parse a config line
- **Purpose.** Read `key = value` as **data** (never `source` a config file) and do integer math.
- **Exact action.**
  ```bash
  IFS='=' read -r k v <<< "top_n = 25"    # split on '='
  read -r key   <<< "$k"                   # a bare read trims surrounding spaces
  read -r value <<< "$v"
  printf 'key=[%s] value=[%s]\n' "$key" "$value"
  echo "$(( value * 2 ))"                   # integer arithmetic
  ```
- **Expected observation (observed).**
  ```text
  key=[top_n] value=[25]
  50
  ```
- **Verification.** No stray spaces inside the brackets; `50` on the last line.
- **Recovery.** `key=[top_n ] value=[ 25]` → you skipped the two trimming `read`s. `syntax error in expression` → `value` still contains a space; trim first.
- **Evidence / next state.** This is precisely how `logsleuth` reads its config file: parsed, whitelisted, never executed. **Why `IFS='='` only on that line:** prefixing a command with `IFS=…` sets it for that command alone; your shell's `IFS` is untouched afterwards.


> **TRAINER ONLY — why "parsed, never sourced" is a security rule, not a style.** Demonstrate with a harmless payload: `printf 'top_n = 3\necho PWNED-by-config\n' > bad.conf`, then `source bad.conf` → prints `PWNED-by-config` (the config *ran*), whereas `while IFS='=' read -r k v; do echo "key=$k"; done < bad.conf` only *reads* it. A config file a user can edit is untrusted input; `logsleuth` whitelists keys (`top_n`, `brute_threshold`) for the same reason. This returns as a critical gate in M09 (`stackctl` must parse `envs/*.conf`, never source it). *Ask:* "What does `IFS='=' read …` do to your shell's IFS afterwards?" *Expected:* "nothing — a prefix assignment applies to that command only."

### S01.7 — Shell variables and the environment: `export` and one-shot assignment
- **Purpose.** A variable you set is yours alone until you `export` it; every tool Course 2 calls — `bao`, `cosign`, `docker`, `kubectl`, the `ci/*.sh` scripts — is a *child process* and sees only the environment. This step shows the three ways a value reaches a child, and one way it does not.
- **Exact action.**
  ```bash
  REGION=test
  bash -c 'echo "child sees: [${REGION:-}]"'        # a plain variable stays in this shell
  export REGION
  bash -c 'echo "child sees: [${REGION:-}]"'        # exported: inherited by every child from now on
  REGION=prod bash -c 'echo "one-shot: [$REGION]"'  # prefix assignment: for that one command only
  echo "after one-shot: [$REGION]"
  export APP_ENV=test KUBE_CONTEXT=staging          # assign and export, several at once
  env | grep -E '^(APP_ENV|KUBE_CONTEXT|REGION)=' | sort
  unset KUBE_CONTEXT
  bash -c 'echo "after unset: [${KUBE_CONTEXT:-}]"'
  export DIGEST=$(false); echo "status=$?"          # the trap: export's status, not the command's
  DIGEST=$(false); echo "status=$?"                 # assign first (status kept), export on its own line
  ```
- **Expected observation (observed).**
  ```text
  child sees: []
  child sees: [test]
  one-shot: [prod]
  after one-shot: [test]
  APP_ENV=test
  KUBE_CONTEXT=staging
  REGION=test
  after unset: []
  status=0
  status=1
  ```
- **Verification.** The first child prints an empty bracket and the second prints `test`; the one-shot child sees `prod` while your shell still holds `test`; the last two statuses are `0` then `1`.
- **Recovery.** The first child already prints `[test]` → `REGION` was exported earlier in this shell (`unset REGION` and start over). `one-shot: []` → a space crept in around the `=`, or you wrote `REGION=prod; bash …` (the semicolon makes it an ordinary assignment, not a prefix). The second-to-last line prints `1` → you wrote the assignment and the `export` on separate lines, which is the correct form, so that is fine.
- **Evidence / next state.** **Why three forms:** `export NAME` (or `export NAME=value`) marks a variable for every child *from now on*; `NAME=value command` sets it for *one* child and leaves your shell alone; a bare `NAME=value` never leaves the shell. **The program's own lines:** Course 2 Lab 2.1 proves a scoped token with `BAO_TOKEN=$SCOPED bao kv get …` — a one-shot that does not touch the real `BAO_TOKEN`; Lab 8.1 runs `COSIGN_PASSWORD=rogue cosign sign …` the same way; Lab 9.1 passes the image to a script with `IMAGE=$IMAGE ./ci/deploy.sh`; Lab 13.1 ends with `export SO_URL SO_TOKEN && ./ci/so_upload.sh` — exporting two *existing* variables so the script can read them. **The trap** is SC2155, which M08's shellcheck gate flags: `export X=$(cmd)` returns `export`'s status (0), so a failed command slips past `set -e`; `ci/release.sh` does exactly this with `export COSIGN_PASSWORD="$(bao kv get …)"`. Write the assignment and the `export` on two lines. `env` prints every exported variable; `unset` removes one from both the shell and future children — M07 S07.6 comes back to that for secrets.


> **TRAINER ONLY (added Batch 7, 2026-10-26; every output observed, bash 5.2).** *Why this step exists:* the Course 2 audit (60 lab/lesson pages, 249 shell blocks) found 26 `export` lines and 23 one-shot `VAR=value cmd` lines that the course never taught; learners met `BAO_TOKEN=$SCOPED bao kv get …` in Lab 2.1 with no model of why the real token was untouched. *Ask:* "After `REGION=prod bash -c '…'`, what does `echo $REGION` print?" *Expected:* `test` — the prefix form sets the variable in the child's environment only. *Tempting wrong answer:* `prod` ("I just assigned it"). *Common error:* `REGION=prod; bash …` (semicolon) — now it *is* an assignment, and the "one-shot" leaks; have them run both. *The SC2155 lines:* if a learner reports `status=1` for `export DIGEST=$(false)`, they typed it on two lines — correct behaviour, wrong experiment; the point is that the *one-line* form hides the failure. *Grading note:* nothing in A-02 changes; the reflection may now mention `export` — accept "a child only sees exported variables" as a correct statement of scope.

---

## Worked demonstration (10 min)

```bash
cd /course
bash labs/lab1-variables/lab.sh
```
**Expected observation (observed).** 24 checks and `---- lab1: 24 passed, 0 failed ----`.
It replays S01.1–S01.6 with assertions, shows `$path` splitting versus `"$path"`
staying whole, proves `logsleuth` analyzes a log file whose name contains a space,
and feeds `logsleuth` a config that sets `top_n = 3` to show `top` honoring it.
Read the source beside the output.


> **TRAINER ONLY — what `lab.sh` asserts (24 checks, observed).** Assignment and `$(…)` capture; the unquoted/quoted split and glob behavior; `${x:-}`, `${#x}`, case conversion; `##`/`%`/`//`/`%%` slicing into `report-access-<date>.txt`; arithmetic and `read` splitting; then the project: `logsleuth` analyzing a log whose *name contains a space*, and a config with `top_n = 3` limiting `top` to three rows. If the "file with a space" check fails on a learner machine, suspect a bind-mounted host path with unusual characters (a macOS folder name with spaces or non-ASCII, or a WSL path under `/mnt/c`, say) rather than the course.

---

## LAB-01 — Your exercise (graded as A-02) — 45 min

**Task.** Implement three helpers in `params.sh` so the grader passes.

| Field | Value |
|---|---|
| Location | `labs/lab1-variables/exercise/` (read `TASK.md`) |
| Starting assets | `starter/params.sh` (three functions returning `FIXME`, each with a `# TODO` quoting the exact move), `grade.sh` |
| Allowed resources | This module, documentation, AI assistance (disclose in reflection); **not** `solution/` |
| Deliverables | `work/params.sh` passing the grader; `work/REFLECTION.md` with R1 and R2 |
| Acceptance | `bash grade.sh` ends `---- lab1: 7 passed, 0 failed ----`; both reflections present |

**Procedure.**
1. `cd labs/lab1-variables/exercise && bash grade.sh` — seeds `work/` from the starter. **Observed:** `---- lab1: 0 passed, 7 failed ----`; every FAIL shows `expected [...], got [FIXME]`.
2. Edit `work/params.sh`:
   - `stem`: `base="${path##*/}"` then `printf '%s\n' "${base%.log}"` (S01.4).
   - `report_name`: `printf 'report-%s-%s.txt\n' "$(stem "$path")" "$date"` (S01.5).
   - `parse_kv`: `IFS='=' read -r k v <<< "$line"`, then `read -r KEY <<< "$k"` and `read -r VALUE <<< "$v"` (S01.6). The grader reads the globals `KEY` and `VALUE`.
3. Re-run until **`---- lab1: 7 passed, 0 failed ----`** (observed with the reference). The seven checks: three `stem` cases (`access.log` → `access`, `auth.log` → `auth`, a path with no suffix), `report_name` → `report-access-2026-10-16.txt`, `parse_kv` key, value, and trimming of `"  brute_threshold=10  "`.
4. `work/REFLECTION.md` (3–5 sentences each):
   - **R1.** Why do `${1:-world}` and `${x:-10}` use a colon? What changes without it?
   - **R2.** In S01.2 `$path` became two arguments. What decides *where* an unquoted value splits, and why is quoting — not changing `IFS` — the right fix?

**Learner-visible rubric (A-02).** *Pass* = grader `0 failed` **and** both reflections name the mechanism (not just "it's safer"). *Not yet* otherwise. Unlimited attempts.

**Hints (graduated).** H1: fix one function at a time; the grader runs top to bottom. H2: `stem a/b/c/app` must print `app` — `${base%.log}` leaves a name without `.log` untouched. H3: for `parse_kv`, print `[$k]` and `[$v]` after the first `read` to *see* the spaces you need to trim.

**Reset / cleanup.** `rm -rf work && bash grade.sh`.


> **TRAINER ONLY — complete solution (reference `solution/params.sh`, observed 7/7):**
> ```bash
> #!/usr/bin/env bash
> # Lab 1 solution — parameter-expansion helpers, the exact moves logsleuth uses.
>
> # stem: /var/log/nginx/access.log -> access   (basename, then drop a .log suffix)
> stem() {
>   local path="$1" base
>   base="${path##*/}"              # strip everything up to the last '/'
>   printf '%s\n' "${base%.log}"    # strip a trailing '.log'
> }
>
> # report_name: compose  report-<stem>-<date>.txt
> report_name() {
>   local path="$1" date="$2"
>   printf 'report-%s-%s.txt\n' "$(stem "$path")" "$date"
> }
>
> # parse_kv: "top_n = 25"  ->  set globals KEY=top_n and VALUE=25 (trimmed)
> parse_kv() {
>   local line="$1" k v
>   IFS='=' read -r k v <<< "$line"
>   read -r KEY   <<< "$k"          # a bare read trims surrounding whitespace
>   read -r VALUE <<< "$v"
> }
> ```
> *Acceptable variations:* `stem` using `basename`/`sed` passes the checks but misses the point — coach toward expansion; `parse_kv` trimming with `${k#"${k%%[![:space:]]*}"}` idioms is correct but over-complex for this level; a `parse_kv` that `local`-izes `KEY`/`VALUE` **fails** (the grader reads globals) — a good teaching moment on scope, picked up in M04.
>
> **Grading procedure (≈5 min/learner).** 1) `GRADE_TARGET=/path/to/their/work bash labs/lab1-variables/exercise/grade.sh` → require `---- lab1: 7 passed, 0 failed ----`. 2) Read `REFLECTION.md`:
> - **R1 — Met:** the colon makes the default apply when the variable is *empty as well as unset*; without it an empty value is kept. **Strong:** gives the observed pair (`${x-10}` → empty line, `${x:-10}` → `10`) or names a case where the difference matters (an optional argument passed as `""`). **Not met:** "the colon is required syntax" or restating the symbol.
> - **R2 — Met:** an unquoted expansion is split on the characters in `IFS` (and globbed); quoting hands the value over as one argument regardless of IFS. **Strong:** notes that changing IFS only changes *which* characters split (tabs/newlines, and `*` still globs), so it is not a fix. **Not met:** "quotes make it a string" or "IFS should be set to avoid splitting" (the misconception to correct).
>
> 3) Record `A-02 PASS` only with 7/7 **and** both reflections ≥ Met. No partial credit; no critical gates.
>
> **Calibration.** *R2 Met:* "Bash splits an unquoted `$path` wherever it finds a character from IFS — a space by default — and then expands wildcards; `"$path"` stops both, so the value stays one argument." *R2 Not met:* "You should always quote variables because it is best practice." (symptom/rule without mechanism — return with the hint "what *decides* where the split happens?").
>
> **Model feedback (Not yet):** "`stem a/b/c/app` returned `var/…`? Your `#` strips the shortest match; you need `##`." **Remediation:** redo S01.4 and S01.6. **Equivalent reassessment:** same grader; **R1'** "Why does `parse_kv` set `KEY`/`VALUE` as globals rather than printing them?" (Met: two values to return; stdout would need parsing; M04 discusses the trade-off) and **R2'** "Give one input that is safe under `IFS=$'\n\t'` but still breaks unquoted." (Met: a value containing `*`, or a tab).
>
> **Evidence handling.** Keep final grader output + `REFLECTION.md`. **Reset:** learners `rm -rf work`.

---

## Knowledge checks (predict, then run)

1. What does `name = logsleuth` (with spaces) do?
2. For `path=/var/log/x.log`, what do `${path##*/}` and `${path#*/}` print?
3. After `IFS='=' read -r k v <<< "a = b"`, what exactly is in `k` and `v`?
4. What does `$(( 7 / 2 ))` print?
5. Which is the default-when-*empty* form: `${v-x}` or `${v:-x}`?
6. `TOKEN=abc bao kv get …` and `export TOKEN=abc; bao kv get …` both let `bao` see the token. What is different afterwards?
7. Why does shellcheck flag `export DIGEST=$(cat image.digest)`?


> **TRAINER ONLY — answers and why the tempting alternatives are wrong.**
> 1. `name: command not found` (exit 127). Tempting: "assigns with spaces trimmed" — bash never trims around `=`.
> 2. `x.log` / `var/log/x.log`. Tempting: both give `x.log` — `#` is *shortest* match.
> 3. `k`=`a ` and `v`=` b` with the spaces. Tempting: "read trims them" — a bare `read` trims only when it has a single variable with default IFS; with `IFS='='` the spaces are kept.
> 4. `3`. Tempting: `3.5` — shell arithmetic is integer-only; use `bc`/`awk` for decimals (not in scope).
> 5. `${v:-x}`. Tempting: either — the colon is the entire difference.
> 6. Scope afterwards: the one-shot form leaves the shell's `TOKEN` as it was (observed `after one-shot: [test]`); `export` persists for the session. Tempting: "both set TOKEN" — only in the child.
> 7. SC2155: `export`'s own status (0) replaces the substitution's, so a failed `cat` passes `set -e` (observed `status=0` vs `status=1`). Tempting: "export cannot take a command substitution" — it can; it just hides the status.

---

## In the SecMLOps Program
Today's expansions are the ones the program's scripts live on. Course 2's `ci/validate_unauth.sh` sets a default with `: "${STAGING:=https://staging.secmlops.com}"` and strips the scheme with `HOST="${STAGING#https://}"` — S01.3's `${var#pattern}` on a real URL. `ci/deploy.sh` does `: "${KUBE_CONTEXT:=staging}"` and `DIGEST="$(cat image.digest)"` — a default and a command substitution, quoted. Course 1's `Makefile` passes values the same way (`make win-agent AZDO_URL=… AZDO_PAT=…`). The quoting rule you learned on a log line with a space in its name is the rule that keeps a `sed -e "s|__IMAGE__|$IMAGE@$DIGEST|"` from breaking on a digest.

---

## Recap and transfer
Quote everything, default the unset, slice with `#`/`%`, compose with `printf`,
parse with `read`, compute with `$(( ))`. **Transfer:** M02 guards and routes on
these values; M09's `stackctl` parses its environment files with exactly the
`parse_kv` discipline — as data, never executed.

---

## Self-check answers (read after attempting)

1. Bash runs a command named `name` → `name: command not found` (exit 127). Assignment has no spaces.
2. `x.log` and `var/log/x.log` — `##` strips the longest leading `*/`, `#` the shortest (just the first `/`).
3. `k` is `a ` (trailing space) and `v` is ` b` (leading space) — `read` split only on `=`; a second bare `read` trims each.
4. `3` — shell arithmetic is integer division.
5. `${v:-x}` (the colon). `${v-x}` substitutes only when `v` is unset, not when it is empty.
6. After the one-shot form your shell has no `TOKEN` at all (observed: `after one-shot: [test]` kept the old value); after `export` every later command in the session inherits it until you `unset` it.
7. SC2155: the line's status is `export`'s (always 0), so a missing `image.digest` would not stop a strict-mode script (observed: `status=0` vs `status=1` when the assignment stands alone).


> **TRAINER ONLY — end of module.** Debrief prompt: "Which of the three helpers would break first on a filename with a space, and why does it not?" (expected: none — every expansion is quoted; that is the deliverable). **Prepare M02:** no new tools; learners keep `work/params.sh` — M02's `validate_log` guards exactly the paths `stem` names. **Session close:** record A-02; collect only `work/params.sh` and `work/REFLECTION.md`.