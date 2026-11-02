# Part 4 — Functions and structure

> Graded by `labs/lab4-functions/exercise/grade.sh`. Turning a script into
> reusable, testable functions. In this part you build logsleuth's two classifier
> functions, each using the right return channel — one reports a *status*, the
> other prints *output*.

**What you'll build.** In `labs/lab4-functions/exercise/` you implement
`is_valid_status` and `status_class` in `classify.sh`. First, the moves.

---

## Step 1 — A function is a mini-script

```bash
greet() { printf 'hello, %s (%d args)\n' "${1:-world}" "$#"; }
greet
greet Antonio
```
```text
hello, world (0 args)
hello, Antonio (1 args)
```

Inside, `$1 $2 …` are the arguments, `$#` the count, `"$@"` all of them. Declare
internal variables `local` so a function never clobbers its caller's variables.

---

## Step 2 — Two ways to return: STATUS vs OUTPUT

A **predicate** returns a *status* (0/non-zero), consumed by `if`/`&&`; it prints
nothing. Let the function's status *be* the test:

```bash
is_valid_status() { [[ "$1" =~ ^[1-5][0-9][0-9]$ ]]; }
is_valid_status 404 && echo "404 ok"
is_valid_status 999 || echo "999 rejected"
```
```text
404 ok
999 rejected
```

A **producer** prints to *stdout*, captured with `$( )`:

```bash
status_class() {
  if is_valid_status "$1"; then printf '%sxx\n' "${1:0:1}"; else printf 'unknown\n'; fi
}
echo "$(status_class 503)"
echo "$(status_class nope)"
```
```text
5xx
unknown
```

`return N` is limited to 0–255 and means success/failure — it is **not** how you
return data. Data goes to stdout.

---

## Step 3 — Libraries: `source` to reuse

`source lib.sh` (or `. lib.sh`) runs a file in the *current* shell, defining its
functions for you to call. That is exactly logsleuth's shape: a thin
`bin/logsleuth` dispatcher that sources `lib/util.sh`, `lib/parse.sh`, and
`lib/report.sh`. Your grader sources *your* `classify.sh` the same way.

---

## Your exercise

Open `labs/lab4-functions/exercise/` and read `TASK.md`. You implement:
- `is_valid_status` — a predicate: 0 for a three-digit `1xx`–`5xx` code, prints nothing.
- `status_class` — a producer: `404` → `4xx`, invalid → `unknown`.

```bash
cd labs/lab4-functions/exercise
bash grade.sh                 # seeds work/ and grades it
# ...edit work/classify.sh...
bash grade.sh                 # until: ---- lab4: N passed, 0 failed ----
```

Notice `status_class` *calls* `is_valid_status` — a predicate guarding a producer,
exactly how logsleuth composes its library.

---

## What you can do at the end of Part 4

Break a program into small, `local`-clean functions; return status or output
deliberately; and assemble a tool from a sourced library. This is the structure
that makes the rest of logsleuth — and your own tools — testable and maintainable.
