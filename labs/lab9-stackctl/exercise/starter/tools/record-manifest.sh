#!/usr/bin/env bash
# record-manifest.sh — write MANIFEST.txt from what THIS machine actually has:
# tool versions, the digest of the image the daemon pulled and the ID of the image
# it built. Nothing here is
# typed by hand; a digest that did not come from `docker image inspect` is a
# fabricated digest and fails CAP-01.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="${1:-$ROOT/MANIFEST.txt}"
docker info >/dev/null 2>&1 || { echo "record-manifest: no Docker daemon reachable" >&2; exit 1; }
{
  echo "# stackctl manifest — recorded $(date -u +%Y-%m-%dT%H:%M:%SZ) on $(hostname)"
  echo "bash $(bash --version | head -1 | awk '{print $4}')"
  echo "docker $(docker version --format '{{.Server.Version}}')"
  echo "compose $(docker compose version --short)"
  for conf in "$ROOT"/envs/*.conf; do
    img="$(grep '^IMAGE_GATEWAY=' "$conf" | cut -d= -f2- | cut -d@ -f1)"
    digest="$(docker image inspect --format '{{index .RepoDigests 0}}' "$img" 2>/dev/null || echo "NOT PULLED")"
    printf '%s IMAGE_GATEWAY %s → %s\n' "$(basename "$conf" .conf)" "$img" "$digest"
    # a locally built image has no registry digest; its content-addressed image ID is the record
    img="$(grep '^IMAGE_SERVE=' "$conf" | cut -d= -f2-)"
    id="$(docker image inspect --format '{{.Id}}' "$img" 2>/dev/null || echo "NOT BUILT")"
    printf '%s IMAGE_SERVE %s → %s (local build of APP_DIR/Dockerfile.course)\n' "$(basename "$conf" .conf)" "$img" "$id"
  done
} | tee "$out"
