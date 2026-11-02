# Lab 4 exercise — functions: status vs output

You build logsleuth's two classifier functions in `classify.sh`, each using the
right return channel.

## What you build
- `is_valid_status` — a **predicate**: returns success/failure (for `if`/`&&`),
  prints nothing. True for a three-digit `1xx`–`5xx` code.
- `status_class` — a **producer**: prints a value (`404` → `4xx`), captured with `$( )`.

## Do it
1. `bash grade.sh` — seeds `work/` and grades it.
2. Edit `work/classify.sh`:
   - `is_valid_status`: let the function's status be the test itself —
     `[[ "$code" =~ ^[1-5][0-9][0-9]$ ]]`.
   - `status_class`: `if is_valid_status "$code"; then printf '%sxx\n' "${code:0:1}"; else printf 'unknown\n'; fi`.
3. Re-run until `---- lab4: N passed, 0 failed ----`.

## Your deliverable
`work/classify.sh` fully green. Notice `status_class` *calls* `is_valid_status` —
a predicate used to guard a producer, exactly how logsleuth composes its library.
