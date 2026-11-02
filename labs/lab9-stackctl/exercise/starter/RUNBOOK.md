# RUNBOOK — stackctl (fill in from your own live runs; no section may stay TODO)

## 1. What this stack is
TODO: two services (serve = the fraud-clf model API built from app/, gateway = nginx, the only published port), two environments (test :18080, prod :18081), where the config lives, what `GET /api/health` through the gateway must return.

## 2. Operate
TODO: the exact commands to validate, plan, bring up, check and look at a given environment, in the order you run them, with one line of what each proves; plus one `curl` that gets a prediction through the gateway.

## 3. Diagnose
TODO: for each symptom below, the command that tells you which it is and what its output looks like:
- `validate` exits 2
- `up` exits 1 on the first run (image build) vs later (health wait timed out)
- `check` exits 3 (body mismatch) vs exits 1 (unreachable, including a wrong HEALTH_PATH)
- `up` exits 1 immediately with "locked"

## 4. Recover
TODO: how to get back to a healthy state for each diagnosis above; how to rebuild the serve image after changing app/; how to destroy and rebuild one environment without touching the other; what you must set before `destroy` and why there is no global prune.

## 5. Versions and digests
TODO: paste the output of `bash tools/record-manifest.sh` (never a digest or image ID from a document).

## 6. Inherited findings (for Course 2 — do not fix here)
TODO: what you noticed in app/ that should worry you (secrets, dependencies, authentication, the image), each with the Course 2 milestone that addresses it. Operate it; do not patch it.
