# M05 — Text pipelines: grep, awk, sort, uniq, sed
**Student Edition · curriculum v2.0.0-draft · self-paced, no fixed duration**

**Outcome LO-06.** You can turn a log into a report with the tools the shell is
uniquely good at: select lines with `grep`, pick fields with `cut`/`awk`, count
with `sort | uniq -c | sort -rn`, filter and total with `awk`, transform with
`sed`/`tr`, feed commands to each other with pipes, here-documents and
process substitution, and read JSON — a scanner report, an API answer — with `jq`.

**What you'll build.** Two of `logsleuth`'s real reports — `top_ips` (the "top
talkers" pipeline behind `logsleuth top`) and `count_class` (the status-class
filter behind `summary`) — in `labs/lab5-text-processing/exercise/` (graded as A-06).

**Prerequisite check.** A-04 passed. You use S03.2 (fields of a log line; the
status is field 9) and S03.3 (counting by key — this module does the same job
with a pipeline, and you will be able to say when each is the better tool).

---

## Activity context for S05.1–S05.8

| Field | Value |
|---|---|
| Execution context | Inside the course container (or fallback shell), in a scratch folder: `mkdir -p ~/bash-course-work/lab5 && cd ~/bash-course-work/lab5` |
| Starting state | `bash tools-check.sh` reports ready (GNU `awk`, `sed`, `sort`, `uniq` present) |
| Validation status | Every expected output in S05.1–S05.8 was **observed** in the authoring environment (bash 5.2.21, GNU coreutils/gawk, GNU grep 3.11, jq 1.7, curl 8.5, Python 3.13; 2026-10-19, additions 2026-10-25/26) |

First create the six-line log every step uses — six requests to the fraud-clf prediction API as its gateway recorded them (a *here-document*: the lines
between `<<'EOF'` and `EOF` go into the file exactly as typed):

```bash
cat > ex.log <<'EOF'
10.0.0.1 - - [16/Oct/2026:13:00:00 -0500] "GET /api/health HTTP/1.1" 200 512 "-" "kube-probe/1.31"
10.0.0.2 - - [16/Oct/2026:13:00:07 -0500] "GET /api/v2/predict HTTP/1.1" 404 153 "-" "curl/8.5.0"
10.0.0.1 - - [16/Oct/2026:13:00:14 -0500] "GET /docs HTTP/1.1" 200 420 "-" "Mozilla/5.0"
198.51.100.7 - - [16/Oct/2026:13:00:21 -0500] "POST /api/predict HTTP/1.1" 500 0 "-" "python-requests/2.19.1"
10.0.0.2 - - [16/Oct/2026:13:00:28 -0500] "GET /docs HTTP/1.1" 200 420 "-" "Mozilla/5.0"
10.0.0.1 - - [16/Oct/2026:13:00:35 -0500] "POST /api/predict HTTP/1.1" 200 173 "-" "python-requests/2.19.1"
EOF
wc -l < ex.log        # expect 6
```

### S05.1 — `grep`: find, count, invert, extract
- **Purpose.** Select lines by pattern — the first move of every log question. (SK-06)
- **Exact action.**
  ```bash
  grep -c ' 200 ' ex.log                  # -c: count matching lines
  grep -vc ' 200 ' ex.log                 # -v: invert the match
  grep -oE '^[0-9.]+' ex.log | sort -u    # -o: print only the match; -E: extended regex
  grep -n -B1 'POST /api/predict' ex.log | cut -c1-30   # -n: line numbers; -B1: one line of context before
  printf 'RUN pip install --no-cache-dir requests==2.19.1\nRUN pip install -r requirements.txt\n' > Dockerfile
  grep -nE 'pip install(?!.*-r requirements)' Dockerfile; echo "status=$?"   # a look-ahead is not extended regex
  grep -nP 'pip install(?!.*-r requirements)' Dockerfile; echo "status=$?"   # -P: Perl regex, where it exists
  ```
- **Expected observation (observed).**
  ```text
  4
  2
  10.0.0.1
  10.0.0.2
  198.51.100.7
  3-10.0.0.1 - - [16/Oct/2026:13
  4:198.51.100.7 - - [16/Oct/202
  5-10.0.0.2 - - [16/Oct/2026:13
  6:10.0.0.1 - - [16/Oct/2026:13
  grep: warning: ? at start of expression
  status=1
  1:RUN pip install --no-cache-dir requests==2.19.1
  status=0
  ```
- **Verification.** `4`, `2`, three IPs in sorted order; four context lines where matches carry `:` and context lines carry `-`; then a `warning` and `status=1` from `-E`, and the single ad-hoc `pip install` line with `status=0` from `-P`.
- **Recovery.** A different first number → check the pattern is a space, `200`, a space, inside the quotes; on this small file `200` without spaces happens to give the same `4`, but `20` gives `6` (observed) — a pattern without its context matches inside timestamps and byte counts on real logs. Nothing from the third command → `-E` missing (`+` is literal in basic regex; observed: no output) or the `^` anchor dropped.
- **Evidence / next state.** **Why the spaces:** `' 200 '` matches the status *field*, not any `200` inside a path or byte count. `grep -c` answers "how many lines" without a second process; `-o` turns grep into an extractor; `-A`/`-B`/`-C` print lines *after*/*before*/*around* a match (Course 2 Lab 13.1 pulls a password out of a credentials file with `grep -A1 SecObserve … | tail -1`). **The look-ahead lesson is a real one:** Course 2 Lab 14.1 proposes the Dockerfile gate `grep -nE 'pip install(?!.*-r requirements)' Dockerfile && { echo "ad-hoc pip install"; exit 1; } || true`. With `-E`, GNU grep does not understand `(?!…)`: it warns, matches *nothing*, and the `|| true` turns that into a quiet pass — a gate that can never fire. `-P` is what the pattern needs (and BSD grep on a Mac without the GNU tools has no `-P` at all; `grep -v -- '-r requirements' | grep 'pip install'` is the portable spelling). When you reach that lab, fix the line before you trust it.

### S05.2 — Pick columns with `cut` and `awk`
- **Purpose.** Reduce each line to the field you care about.
- **Exact action.**
  ```bash
  cut -d' ' -f1 ex.log | head -2          # cut: split on one delimiter, take field 1
  awk '{print $9}' ex.log | tr '\n' ' '   # awk: fields split on runs of whitespace
  echo
  printf 'harbor_admin_password: "Harbor12345"\r\n' > line.txt   # a key: "value" line with Windows line endings
  awk '{print $2}' line.txt | cat -A                              # cat -A shows the invisible characters
  awk '{print $2}' line.txt | tr -d '"\r' | cat -A               # tr -d: delete the quotes and the CR
  echo 'harbor.secmlops.com/mlops/serve@sha256:abc123' | cut -d@ -f2
  echo 'SecObserve admin password: s3cret' | awk '{print $NF}'  # $NF: the last field
  ```
- **Expected observation (observed).**
  ```text
  10.0.0.1
  10.0.0.2
  200 404 200 500 200 200
  "Harbor12345"^M$
  Harbor12345$
  sha256:abc123
  s3cret
  ```
- **Verification.** Two IPs, the six status codes on one line, then the value first with `"` and `^M` (a carriage return) and then clean, the digest after the `@`, and the last word of the sentence.
- **Recovery.** `$9` printed something else → your `ex.log` lines differ from the block above (the timestamp must be two tokens, S03.2). `awk: command not found` → the container has gawk; in a fallback shell install `gawk`.
- **Evidence / next state.** **Why both:** `cut` is fast and literal (one delimiter character); `awk` splits on *any* whitespace run and is where filters and sums live (S05.4). Field 9 is the status, exactly as in M03. **The program's own idiom:** Course 2 Labs 2.1, 8.1 and 9.1 fetch a lab password with `vagrant ssh -c 'sudo grep harbor_admin_password …' | awk '{print $2}' | tr -d '"\r'` — the fourth and fifth lines above. The `\r` is there because output that crossed a Windows host or a terminal emulator carries CRLF line endings; a stray carriage return inside a password is the kind of bug that looks like "wrong password" for an hour. `cut -d@ -f2` is how Labs 8.1 and 9.1 take the digest off `docker inspect`'s `name@sha256:…`; `$NF` is the last field however many there are.

### S05.3 — The counting pipeline
- **Purpose.** Learn the one idiom that answers "which value is most frequent?" — the backbone of `logsleuth top`.
- **Exact action.**
  ```bash
  awk '{print $1}' ex.log | sort | uniq -c | sort -rn
  awk '{print $1}' ex.log | sort | uniq -c | sort -rn | awk '{print $2, $1}'   # reshape to "<ip> <count>"
  awk '{print $1}' ex.log | uniq -c                                            # the mistake: no sort
  ```
- **Expected observation (observed).**
  ```text
        3 10.0.0.1
        2 10.0.0.2
        1 198.51.100.7
  10.0.0.1 3
  10.0.0.2 2
  198.51.100.7 1
        1 10.0.0.1
        1 10.0.0.2
        1 10.0.0.1
        1 198.51.100.7
        1 10.0.0.2
        1 10.0.0.1
  ```
- **Verification.** Counts 3/2/1 in the first two blocks; six `1`s in the third.
- **Recovery.** Counts of `1` everywhere in the first block → `sort` is missing before `uniq -c` (that is exactly what the third command shows on purpose). The second block still reads `3 10.0.0.1` → you left off the final `awk '{print $2, $1}'`.
- **Evidence / next state.** **Why sort first:** `uniq -c` collapses *adjacent* duplicates only; sorting makes equal values adjacent. `sort -rn` orders by the numeric count, descending. The final `awk` swaps the columns into the shape a report wants. Add `| head -n "$n"` for a top-N.

### S05.4 — `awk` filters, totals, and shell variables
- **Purpose.** Filter and aggregate in one pass, and pass a shell value into awk the safe way.
- **Exact action.**
  ```bash
  awk '$9 ~ /^4/ {c++} END{print c+0}' ex.log       # how many 4xx
  awk '$9 ~ /^3/ {c++} END{print c+0}' ex.log       # how many 3xx (none)
  awk '{b+=$10} END{print b}' ex.log                # total bytes (field 10)
  d=2; awk -v d="$d" '$9 ~ ("^" d) {c++} END{print c+0}' ex.log   # class from a shell variable
  ```
- **Expected observation (observed).**
  ```text
  1
  0
  1678
  4
  ```
- **Verification.** Four lines: `1`, `0`, `1678`, `4`.
- **Recovery.** An empty line instead of `0` → you wrote `print c` without `+0` (an unset awk variable prints as empty). `awk: syntax error` on the last line → the pattern must be built as `("^" d)` with the parentheses, and `d` passed with `-v`.
- **Evidence / next state.** **Why `-v`:** the awk program is in single quotes, so `$d` would never expand inside it; `-v d="$d"` hands the value in as *data*. `END{…}` runs once after the last line; `c+0` forces a number. This is `count_class`.

### S05.5 — `sed`, here-documents, here-strings, process substitution
- **Purpose.** Transform text and feed commands to each other without temp files.
- **Exact action.**
  ```bash
  sed -n '2p' ex.log | sed -E 's/.*" ([0-9]{3}) .*/\1/'   # capture group: the status of line 2
  tr a-z A-Z <<< 'hi'                                      # here-string: a string as stdin
  awk '{print $9}' ex.log | sort -u | tr '\n' ' '; echo    # the distinct statuses
  diff <(awk '{print $9}' ex.log | sort -u) <(printf '200\n404\n500\n') && echo "same set"
  comm -13 <(awk '{print $7}' ex.log | sort -u) <(printf '/api/health\n/api/predict\n/api/v2/predict\n/docs\n/metrics\n' | sort -u)
  ```
- **Expected observation (observed).**
  ```text
  404
  HI
  200 404 500
  same set
  /metrics
  ```
- **Verification.** Five lines as shown; the last is the one path in the second list that the log never saw.
- **Recovery.** `sed: -e expression #1, char 23: invalid reference \1 on …s' command's RHS` (observed; the message quotes `s` with a backtick, elided here) → the `-E` is missing (without it, groups are written `\(` `\)`). `diff` prints differences → your `ex.log` differs from the block above.
- **Evidence / next state.** **Why:** `sed -E 's/PATTERN/REPLACEMENT/'` rewrites a line, and `\1` is what the first `( )` captured. `<<< 'text'` is a here-string (one line of stdin); `<<'EOF'` is a here-document (many lines, used above to create `ex.log`). `<( cmd )` is **process substitution**: it gives a command's output a file name, so tools that want *files* — `diff`, `comm`, `sort -m` — can read pipelines. `comm -13 A B` prints the lines only in `B` (both inputs sorted; `-1`/`-2`/`-3` *suppress* a column) — Course 2 Lab 11.2 measures the authenticated-only attack surface with exactly `comm -13 <(sort -u urls-unauth.txt) <(sort -u urls-auth.txt)`.

### S05.6 — JSON from the shell: `jq`
- **Purpose.** Half of the program's scripts read JSON — scanner reports, API answers — and they do it with `jq`: select a field, flatten a list, and turn a question into an exit code. (SK-06)
- **Exact action.** The files are course-authored samples in the shapes Course 2's scripts read (`program/README.md`):
  ```bash
  cd /course
  jq '.count' program/fixtures/so-count.json
  jq '.results[0].title' program/fixtures/so-count.json
  jq -r '.results[0].title' program/fixtures/so-count.json
  jq -r '.runs[].results[] | "\(.level)\t\(.ruleId)"' program/fixtures/nuclei-unauth.sarif
  jq -r '.runs[].results[].level' program/fixtures/nuclei-unauth.sarif | sort | uniq -c | sort -rn
  jq -e '[.runs[].results[] | select(.level=="error")] | length > 0' program/fixtures/nuclei-unauth.sarif; echo "status=$?"
  jq -e '[.runs[].results[] | select(.level=="error")] | length > 0' program/fixtures/testssl.sarif; echo "status=$?"
  jq '.coutn' program/fixtures/so-count.json; jq -e '.coutn' program/fixtures/so-count.json; echo "status=$?"
  jq '[.runs[].results[]] | length' program/fixtures/nuclei-unauth.sarif   # collect into a list, then count
  jq -c '.results[0] | {title, severity}' program/fixtures/so-count.json   # build a smaller object; -c: one line
  jq '.runs[0].tool.driver.nmae // "unknown"' program/fixtures/nuclei-unauth.sarif   # //: a default for null
  jq -r '.payload' program/fixtures/attestation.json | base64 -d | jq '.predicate.components | length'
  ```
- **Expected observation (observed, jq 1.7).**
  ```text
  3
  "requests 2.19.1 — CVE-2018-18074"
  requests 2.19.1 — CVE-2018-18074
  warning	tls-version
  note	exposed-docs
  error	unauth-predict
        1 warning
        1 note
        1 error
  true
  status=0
  false
  status=1
  null
  null
  status=1
  3
  {"title":"requests 2.19.1 — CVE-2018-18074","severity":"High"}
  "unknown"
  3
  ```
- **Verification.** Nineteen lines; the two `-e` statuses are `0` then `1`; the typo `.coutn` prints `null` both times and `-e` turns the second into `status=1`; the last four are `3`, a one-line object, `"unknown"` and `3`.
- **Recovery.** `jq: error … Cannot iterate over null` → the path is wrong (`.runs[]` on a file without `runs`); print the top level first with `jq 'keys'`. Quotes around the title in the third line → you forgot `-r`. `parse error` → the file is not JSON (a scanner that failed may write an empty file — exactly why the program's gate reports `UNREADABLE REPORT` and exits 1 instead of passing).
- **Evidence / next state.** **Why `jq`:** `grep`/`awk` work on *lines*; JSON is a *tree*, and a value can be split across lines or nested — a line tool will one day miss it. **The three moves:** a **path** (`.count`, `.results[0].title`), **iteration** (`.runs[].results[]` flattens every result of every run), and a **filter** (`select(.level=="error")`), plus `-r` for raw strings and `-e` to make the *truth* of the result the exit code — `true` → 0, `false`/`null` → 1 — so a `jq` call can sit in an `if` or before `&&` like any other test. **The program's own lines:** `ci/validate_unauth.sh` runs `n=$(jq '[.runs[].results[] | select(.level=="error")] | length' "$s")` on every SARIF file and fails the stage on anything but `0` — the fifth command's filter with `| length` in place of `-e … > 0`, so the count is data and the `case` on it is the gate; `ci/so_upload.sh` posts reports to SecObserve and the chapter's checks read `| jq '.count'` from its API — the first command. `program/ci/sarif_gate.sh` does the same count in Python instead; M08 S08.5 compares the two. **Four more shapes you will meet:** `[ … ] | length` collects an iteration into a list and counts it (Lab 7.1 sums vulnerabilities with `[.Results[]?.Vulnerabilities // [] | length] | add`); `{title, severity}` builds a new object from chosen keys (Lab 13.1 prints `{id, name}` for each product it creates); `a // b` substitutes `b` when `a` is `null` or missing (the `// []` above keeps a missing list from breaking the sum); and `jq -r .payload | base64 -d | jq …` is how Chapter 8 reads what `cosign verify-attestation` returns — an envelope whose `payload` is a base64-encoded JSON statement. `program/fixtures/attestation.json` is a course-authored sample of that envelope. A key with a dash needs brackets: `.["template-id"]` (Lab 11.1).

### S05.7 — Here-documents that write files and feed programs
- **Purpose.** You have used `<<'EOF'` to create `ex.log`. Course 2 uses here-documents twenty-five times in its labs — to write a whole script (`cat > ci/gates.sh <<'EOF'`), to append to one, to send a policy to `bao policy write … -`, a manifest to `kubectl apply -f -`, and a program to `python3 -`. Two details decide whether that works: the quotes around the delimiter, and the `-`.
- **Exact action.**
  ```bash
  cd ~/bash-course-work/lab5
  NAME=world
  cat > a.txt <<EOF
  hello $NAME, first arg is $1
  EOF
  cat > b.txt <<'EOF'
  hello $NAME, first arg is $1
  EOF
  cat a.txt b.txt
  cat > gate.sh <<'EOF'
  #!/usr/bin/env bash
  set -euo pipefail
  echo "arg: ${1:?usage: gate.sh FILE}"
  EOF
  cat >> gate.sh <<'EOF'
  echo "GATE-PASS"
  EOF
  bash -n gate.sh; echo "syntax status=$?"      # -n: parse only, run nothing
  bash gate.sh report.sarif
  printf 'if true\n  echo x\n' > broken.sh; bash -n broken.sh; echo "syntax status=$?"
  python3 - <<'EOF'
  import json; print(json.load(open("/course/program/fixtures/so-count.json"))["count"])
  EOF
  ```
- **Expected observation (observed).**
  ```text
  hello world, first arg is 
  hello $NAME, first arg is $1
  syntax status=0
  arg: report.sarif
  GATE-PASS
  broken.sh: line 3: syntax error: unexpected end of file
  syntax status=2
  3
  ```
- **Verification.** The first line has `world` substituted and nothing after `is`; the second keeps `$NAME` and `$1` literally; `bash -n` reports `0` for the good script and `2` with a `syntax error` for the broken one; the Python program prints `3`.
- **Recovery.** `gate.sh: line 3: 1: usage: gate.sh FILE` → you ran `bash gate.sh` without the argument — that message *is* S06.6's required-input guard working. The second `cat` prints `hello world…` too → you wrote `<<EOF` instead of `<<'EOF'`. `warning: here-document … delimited by end-of-file` → the closing `EOF` is indented or has trailing spaces; it must be alone on its line, at column 1.
- **Evidence / next state.** **Why the quotes:** with `<<EOF` the shell expands `$NAME` and `$1` *before* the text reaches the file — fine for a config, fatal for a script, whose `$1` would vanish; `<<'EOF'` passes every character through. Every `cat > ci/*.sh <<'EOF'` in Course 2 is quoted for that reason, and `cat >> file <<'EOF'` (Lab 4.2) appends instead of replacing. **The `-`:** many tools read a file argument, and `-` means "the file is my stdin" — `python3 - <<'EOF'` runs the program you type (Labs 1.1, 6.1, 7.2, 12.2 do this), `bao policy write ci-mlops - <<'EOF'` (Lab 2.1) and `kubectl apply -f - <<'EOF'` (Lab 10.1) read the document the same way. **`bash -n`** is the cheapest test there is: Course 2 Labs 11.2 and 13.2 end with `bash -n ci/validate_unauth.sh` as their "did I write a valid script" check; put it before `shellcheck` (S00.9) in your own habits.

### S05.8 — HTTP from the shell: `curl`, status codes, and JSON answers
- **Purpose.** Half of Course 2's proofs are an HTTP status code: `302` means Pomerium redirected you, `403` the policy denied you, `000` the connection never happened. `curl` is how a script asks a service a question; `jq` (S05.6) reads the answer. This step runs against a server on your own machine so every number is yours.
- **Exact action.** (One server, started once in the background; `kill` it at the end — M07 S07.4 explains `$!`.)
  ```bash
  cd /course
  python3 -m http.server 8000 --bind 127.0.0.1 --directory program/fixtures >/dev/null 2>&1 &
  SERVER=$!; sleep 1
  curl -s http://127.0.0.1:8000/so-count.json | jq '.count'
  curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8000/so-count.json
  curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8000/missing.json
  curl -sf http://127.0.0.1:8000/missing.json; echo "status=$?"
  curl -sI http://127.0.0.1:8000/so-count.json | head -1
  curl -s -o /dev/null -w '%{http_code}\n' -X POST -H 'Content-Type: application/json' -d '{"instances":[[1,2]]}' http://127.0.0.1:8000/so-count.json
  curl -s -o /dev/null -w '%{http_code}\n' -H 'Authorization: Bearer not-a-real-token' http://127.0.0.1:8000/so-count.json
  curl -s -m 2 -o /dev/null -w '%{http_code}\n' http://127.0.0.1:1/ || echo "BLOCKED (expected)"
  for f in so-count.json testssl.sarif nothing.json; do
    code=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:8000/$f")
    printf '%-16s %s\n' "$f" "$code"
  done
  kill "$SERVER"; wait "$SERVER" 2>/dev/null; echo "server stopped"
  ```
- **Expected observation (observed, curl 8.5, Python 3.13).**
  ```text
  3
  200
  404
  status=22
  HTTP/1.0 200 OK
  501
  200
  000
  BLOCKED (expected)
  so-count.json    200
  testssl.sarif    200
  nothing.json     404
  server stopped
  ```
- **Verification.** `3`, then `200`, `404`, `status=22`, a `200 OK` header line, `501`, `200`, `000` followed by `BLOCKED (expected)`, a three-row table with aligned codes, and `server stopped`.
- **Recovery.** `curl: (7) Failed to connect` on the first line → the server is not up yet (raise `sleep 1` to `sleep 3`) or port 8000 is taken (`SERVER` has exited; pick 8001 everywhere). `Address already in use` (visible if you drop the `>/dev/null 2>&1`) → a previous server is still running: `pkill -f 'http.server 8000'`. **Do not** start the server as `( cd program/fixtures && python3 -m http.server … ) &` — then `$!` is the *subshell*, `kill` ends the subshell and the server lives on as an orphan (observed while authoring; it kept port 8000 for the next run). `--directory` keeps the server itself as the background job. The `for` table shows `000` for every file → same cause. `jq: parse error` on the first line → you fetched the directory listing (HTML), not the file — check the path.
- **Evidence / next state.** **Why these flags:** `-s` silences the progress meter; `-o /dev/null -w '%{http_code}\n'` throws the body away and prints only the status — the shape of every access-matrix line in Course 2 Labs 10.1/10.2; `-f` makes an HTTP error an *exit status* (`22`) so a script can `||` on it (`curl -sf` in `ci/so_upload.sh` and `ci/promote_check.sh`); `-I` asks for headers only (`curl -sI … | head -1`, Lab 10.2); `-X POST -d … -H 'Content-Type: …'` sends a body — the fixture server answers `501` because it does not implement POST, which is the point: the *status* told you; `-H 'Authorization: Bearer …'` is how a token travels (the fixture server ignores it, Pomerium will not); `-m 2` caps the wait, and a connection that never happens prints `000` *and* fails, so `|| echo "BLOCKED (expected)"` is how Lab 10.2 records that a bypass was blocked — a red result that is the green you wanted. **The loop with `printf '%-16s %s\n'`** (left-aligned, 16 wide) is Lab 10.2's access matrix and `scripts/ready-check.sh`'s `ok`/`FAIL` columns. **`&`, `$!`, `kill`, `wait`:** a command ending in `&` runs in the background; `$!` is its process id; M07 S07.4 does the rest.

---

## Worked demonstration (10 min)

```bash
cd /course
bash labs/lab5-text-processing/lab.sh
```
**Expected observation (observed).** `---- lab5: 20 passed, 0 failed ----`. On the
140-line fixture it counts `401`s with `grep -c` (40), inverts with `-v` (55
non-200 lines), extracts an IP with `-oE`, picks columns with `cut` and `awk`,
runs the counting pipeline (top talker `10.0.0.1` with 50; four distinct IPs),
transforms with `tr` and `sed -E`, filters and sums with `awk` (5 lines of 5xx;
50 of 4xx), exercises `>`/`>>`, a here-doc, a here-string and `diff <( ) <( )`,
and finally proves that *your* top-3 pipeline and 4xx count match what
`logsleuth top` and `logsleuth summary` report.

---

## LAB-05 — Your exercise (graded as A-06) — 55 min

| Field | Value |
|---|---|
| Location | `labs/lab5-text-processing/exercise/` (read `TASK.md`) |
| Starting assets | `starter/reports.sh` (two functions with `# TODO`s), `grade.sh` — regenerates the fixture logs on every run via the course's `seed/make_logs.sh` |
| Allowed resources | This module, documentation, AI assistance (disclosed); **not** `solution/` |
| Deliverables | `work/reports.sh` passing the grader; `work/REFLECTION.md` with R1 and R2 |
| Acceptance | `bash grade.sh` ends `---- lab5: 5 passed, 0 failed ----`; both reflections present |

**Procedure.**
1. `cd labs/lab5-text-processing/exercise && bash grade.sh`. **Observed on the starter:** `---- lab5: 0 passed, 5 failed ----`.
2. Edit `work/reports.sh`:
   - `top_ips`: the S05.3 pipeline on field 1, limited with `head -n "$n"`, reshaped to `<ip> <count>` (most frequent first).
   - `count_class`: the S05.4 `awk -v d="$d"` filter on field 9, printing `c+0`.
3. Re-run until **`---- lab5: 5 passed, 0 failed ----`** (observed with the reference). The checks: `top_ips … 1` → `10.0.0.1 50`; `top_ips … 3` prints 3 lines; `count_class … 4` → `50`; `… 5` → `5`; `… 2` → `85`.
4. `work/REFLECTION.md`:
   - **R1.** Why must the pipeline `sort` before `uniq -c`? Say what `uniq` actually compares, and what the top-talkers report would show without the sort.
   - **R2.** `count_class` passes the class digit with `awk -v d="$d"`. Why not write the digit straight into the awk program (`'$9 ~ /^'"$d"'/'`)? Name the mechanism and one input that would break the spliced version.

**Learner-visible rubric (A-06).** *Pass* = `0 failed` **and** both reflections name the mechanism. Unlimited attempts.

**Hints.** H1: the last `awk` in `top_ips` only *reorders* two columns — `{print $2, $1}`. H2: `head -n "$n"`, quoted; `head -$n` is the old form and shellcheck will object. H3: `END{print c+0}` — the `+0` is what makes an empty count print as `0`.

**Reset.** `rm -rf work && bash grade.sh`.

---

## Knowledge checks (predict, then run)

1. What does `uniq -c` do with two equal lines that are *not* adjacent?
2. In `awk -v d="$d" '$9 ~ ("^" d)'`, what would happen to `$d` if it were written inside the single-quoted program instead?
3. What does `grep -c PATTERN file` print, and how is it different from `grep PATTERN file | wc -l`?
4. What is `<(cmd)`, and which kind of command needs it?
5. Why does `END{print c+0}` print `0` rather than an empty line when nothing matched?
6. `jq '.coutn' file.json` prints `null` and exits 0. What does `-e` change, and why does a gate need it?
7. `cat > run.sh <<EOF` (unquoted) writes a script containing `echo "$1"`. What ends up in the file?
8. `curl -s -o /dev/null -w '%{http_code}\n' URL` prints `000`. What happened, and what does `-f` add that `-w` does not?

---

## In the SecMLOps Program
The six lines you worked on are the fraud-clf API's gateway log; in Course 2 you will read the real one. `ci/deploy.sh` renders a Kubernetes manifest with `sed -e "s|__IMAGE__|$IMAGE@$DIGEST|" -e "s|__ENV__|$APP_ENV|" k8s/serve.yaml | kubectl apply -f -` — the same `sed` templating `stackctl` uses in M09, piped straight into the apply. Course 1's `scripts/replica-check.sh` is `grep -E` and `awk '{print $2, $3}'` over two hosts' tool lists, then `diff`. The `awk -v` rule from S05.4 is why none of those scripts splice a shell variable into an awk program. Twelve of the program's scripts parse JSON with `jq` (S05.6); the SARIF gate in `ci/validate_unauth.sh` is the one you just ran against the fixtures.

**Read the real thing (5 min).** Open `program/ci/validate_unauth.sh` (a real Course 2 script, shipped read-only). Answer in `notes/M05-read.txt`: (a) which line is the gate and what exit code it produces when a report has an `error`-level result; (b) why every scanner line ends in `|| true` and the script starts with `set -uo pipefail` rather than `set -euo pipefail`; (c) the gate names three outcomes — `MISSING REPORT`, `UNREADABLE REPORT`, `CRITICAL` — why is a missing report a *failure* and not simply skipped? Answers at the end of the page.

---

## Recap and transfer
Select with `grep`, pick with `cut`/`awk`, count with `sort | uniq -c | sort -rn`,
filter and total with `awk`, transform with `sed`/`tr`, connect with pipes,
here-docs, here-strings and `<( )`. **Transfer:** M06 puts these reports behind a
real command line; M08 tests them against fixtures with exact counts; M09's
`stackctl status` and `check` read `docker compose ps` and an HTTP body with the
same `awk`/`diff` moves.

---

## Self-check answers

1. It counts them separately — `uniq` compares each line only with the one *before* it (observed: six `1`s without `sort`).
2. Nothing — single quotes stop expansion, so awk would see the literal characters `$d`, not your value; written as `/^$d/` the filter silently matches nothing (observed: `0` for every class).
3. The number of matching lines; the same number as the pipeline, but counted inside grep with no second process and no newline-counting subtleties.
4. Process substitution — the output of `cmd` appears as a file name; needed by tools that take *files* rather than stdin, such as `diff` with two inputs (observed: `same set`).
5. An awk variable that was never assigned is the empty string; `+0` converts it to the number `0` (observed: `0` vs an empty line).
6. Without `-e`, `jq` exits 0 whenever it *ran*; `null` is a valid result. With `-e` the exit status reflects the last output's truth — `false` and `null` give 1 — so a typo in a path, or a report with no findings, becomes a visible status instead of a silent pass. (Observed: `jq '.coutn'` → `null`, status 0; `jq -e '.coutn'` → `null`, status 1.)
7. `echo ""` — the shell expanded `$1` (empty at the prompt) before `cat` saw the text (observed: `first arg is ` with nothing after it); quote the delimiter, `<<'EOF'`, to keep `$1` (S05.7).
8. No HTTP exchange happened at all — refused, unreachable or timed out — so there is no status to print (observed with port 1); `-w` only *reports*, while `-f` turns an HTTP error (4xx/5xx) into exit status 22 so `||` and `set -e` can act on it (S05.8).

**Read the real thing.** (a) The `sarif_gate` function's `case`: `n=$(jq '[.runs[].results[] | select(.level=="error")] | length' "$s")` and any `n` other than `0` prints `CRITICAL in $s: … finding(s)` and exits **1** (observed with the course fixture: `CRITICAL in nuclei-unauth.sarif: 1 error-level finding(s)`, status 1). (b) The scanners (`nmap`, `katana`, `nuclei`, `testssl.sh`) return non-zero when they *find* things or when a target is slow; under `-e` the script would stop before the gate ran, so each scanner is allowed to fail (`|| true`) and only the gate decides. (c) Because every scanner line ends in `|| true`, a scanner killed by a timeout leaves *no report and no error* — and a stage that skipped missing files would print `PHASE1-DONE` with status 0, indistinguishable from a clean scan. The gate therefore requires the file (`MISSING REPORT`, observed: status 1 for `nope.sarif`) and requires it to parse (`UNREADABLE REPORT`), so the only way to pass is a report that exists, is valid SARIF, and holds no `error`-level result. The one-liner this replaced, `[ -f "$s" ] && jq -e … && { exit 1; }`, had exactly that hole; M07's reading exercise shows how it was found.
