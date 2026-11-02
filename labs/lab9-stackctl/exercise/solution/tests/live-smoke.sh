#!/usr/bin/env bash
# live-smoke.sh — the ONLY evidence that the stack really provisions.
# Needs a running Docker daemon with the Compose plugin. Exercises one environment end to end
# and leaves nothing behind. Attach its transcript to CAP-01 evidence.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
ENV_NAME="${1:-test}"
sc() { bash "$ROOT/bin/stackctl" -e "$ENV_NAME" "$@"; }

docker info >/dev/null 2>&1 || { echo "live-smoke: no Docker daemon reachable" >&2; exit 1; }
echo "== live smoke for $ENV_NAME ($(date -u +%Y-%m-%dT%H:%M:%SZ)) =="
docker version --format 'docker {{.Server.Version}}'; docker compose version
sc validate
sc plan
sc up
sc check
curl -fsS -X POST "http://127.0.0.1:$(grep '^PORT=' "$ROOT/envs/$ENV_NAME.conf" | cut -d= -f2)/api/predict" -H 'content-type: application/json' -d '{"instances": [[120.0, 14, 0.2, 1]]}'; echo
sc status
sc plan | grep -q 'up would: nothing' && echo "converged: plan reports nothing to do"
sc up                                  # idempotent re-run
sc logs | tail -5
CONFIRM_DESTROY="$ENV_NAME" sc destroy
if docker compose ls --format '{{.Name}}' 2>/dev/null | grep -qx "$(grep '^PROJECT=' "$ROOT/envs/$ENV_NAME.conf" | cut -d= -f2)"; then
  echo "live-smoke: project still listed after destroy" >&2; exit 1
fi
echo "== live smoke OK =="
