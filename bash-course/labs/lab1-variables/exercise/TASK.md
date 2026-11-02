# Lab 1 exercise — variables, quoting, and parameter expansion

You implement three small helpers that logsleuth really uses, in `params.sh`.

## What you build
- `stem` — turn a log path into a clean name: `/var/log/nginx/access.log` → `access`.
- `report_name` — compose a report filename: `report-access-2026-10-16.txt`.
- `parse_kv` — read one `key = value` config line into `KEY` and `VALUE`, trimmed.

## Do it
1. Run the grader once:
   ```bash
   bash grade.sh
   ```
   It copies the starter into `work/` and grades it — every check **FAILs**
   because the functions still return `FIXME`. That failing list is your to-do.
2. Edit `work/params.sh` and complete each `# TODO` with the lesson's moves:
   - `stem`: `${path##*/}` for the basename, then `${base%.log}` to drop `.log`.
   - `report_name`: `printf 'report-%s-%s.txt\n' "$(stem "$path")" "$date"`.
   - `parse_kv`: `IFS='=' read -r k v` to split, then a bare `read -r KEY <<< "$k"`
     (a plain `read` trims surrounding whitespace for free).
3. Re-run `bash grade.sh` until you see:
   ```
   ---- lab1: N passed, 0 failed ----
   ```

## Your deliverable
`work/params.sh` with every check green. Compare against `solution/params.sh`
only after you have it passing (or if you get stuck).
