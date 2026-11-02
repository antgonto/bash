# Lab 3 exercise — loops and associative arrays

You build logsleuth's counting core in `counters.sh` — the heart of log analysis.

## What you build
- `count_status` — read an access log line by line and tally status codes (field 9)
  into an associative array, printing `<code> <count>` sorted by code.
- `bruteforce_count` — count the failed sshd logins from a given IP in an auth log.

## Do it
1. `bash grade.sh` — it generates deterministic fixture logs (200=85, 401=40,
   500=5; IP `203.0.113.9` has 25 failed logins) and grades your work.
2. Edit `work/counters.sh`:
   - read lines with `while IFS= read -r line; do … done < "$f"`.
   - split a line with `read -ra parts <<< "$line"`; field 9 is `${parts[8]}`.
   - count safely under `set -u`: `n["$code"]=$(( ${n["$code"]:-0} + 1 ))`.
3. Re-run until `---- lab3: N passed, 0 failed ----`.

## Your deliverable
`work/counters.sh` fully green. This counter *is* logsleuth's `cmd_bruteforce`.
