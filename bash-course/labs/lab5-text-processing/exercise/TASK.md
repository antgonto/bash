# Lab 5 exercise — the text-processing toolkit

You build two of logsleuth's reports as shell pipelines in `reports.sh`.

## What you build
- `top_ips` — the "top N" one-liner: `sort | uniq -c | sort -rn`, printed as
  `<ip> <count>`.
- `count_class` — an `awk` filter counting responses in a status class (4 → 4xx).

## Do it
1. `bash grade.sh` — generates fixture logs (top IP `10.0.0.1` = 50; 4xx = 50,
   5xx = 5, 2xx = 85) and grades your work.
2. Edit `work/reports.sh`:
   - `top_ips`: `awk '{print $1}' "$f" | sort | uniq -c | sort -rn | head -n "$n" | awk '{print $2, $1}'`.
   - `count_class`: `awk -v d="$d" '$9 ~ ("^" d) {c++} END{print c+0}' "$f"`.
3. Re-run until `---- lab5: N passed, 0 failed ----`.

## Your deliverable
`work/reports.sh` fully green — the same pipelines behind `logsleuth top` and `summary`.
