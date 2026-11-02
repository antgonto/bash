# shellcheck shell=bash
# driver.sh — the only place stackctl talks to Docker or the network.
#
# STACKCTL_DRIVER=docker (default) runs `docker compose` and `curl`.
# STACKCTL_DRIVER=mock   records every call and simulates state on disk so the
#                        control logic can be tested without a daemon.
#
# The mock is NOT evidence that a stack can be provisioned; it proves only
# that stackctl makes the right calls in the right order with the right flags.

err()  { printf '%s: %s\n' "$PROG" "$*" >&2; }
info() { printf '%s\n' "$*"; }

MOCK_STATE="${STACKCTL_MOCK_STATE:-${TMPDIR:-/tmp}/stackctl-mock}"

# drv_compose PROJECT FILE ARGS...   →  docker compose --project-name PROJECT -f FILE ARGS...
drv_compose() {
  local project="$1" file="$2"; shift 2
  if [[ "${STACKCTL_DRIVER:-docker}" == mock ]]; then
    mock_compose "$project" "$file" "$@"
  else
    docker compose --project-name "$project" -f "$file" "$@"
  fi
}

# drv_http_get URL   →  body on stdout, non-zero if unreachable or not 2xx
drv_http_get() {
  if [[ "${STACKCTL_DRIVER:-docker}" == mock ]]; then
    mkdir -p "$MOCK_STATE"
    printf 'GET %s\n' "$1" >> "$MOCK_STATE/calls.log"
    [[ -n "${STACKCTL_MOCK_DOWN:-}" ]] && return 7      # curl's "could not connect"
    local default_body='{"status":"ok"}'
    printf '%s' "${STACKCTL_MOCK_HEALTH-$default_body}"
  else
    curl -fsS --max-time 5 "$1"
  fi
}

mock_compose() {
  local project="$1" file="$2"; shift 2
  mkdir -p "$MOCK_STATE"
  local IFS=' '                      # "$*" joins with the first char of IFS; the house IFS starts with newline
  printf 'compose %s %s\n' "$project" "$*" >> "$MOCK_STATE/calls.log"
  local running="$MOCK_STATE/$project.running"
  case "$1" in
    config)
      grep -q '^services:' "$file" || { echo "mock: not a compose file: $file" >&2; return 1; }
      [[ "${2:-}" == -q ]] || cat "$file" ;;
    up)
      [[ -n "${STACKCTL_MOCK_FAIL_UP:-}" ]] && { echo "mock: up failed (simulated)" >&2; return 1; }
      printf 'serve\ngateway\n' > "$running" ;;
    ps)
      [[ -f "$running" ]] && cat "$running"; return 0 ;;
    logs)
      printf 'mock: logs for project %s\n' "$project" ;;
    down)
      rm -f "$running" ;;
    *)
      echo "mock: unsupported compose command: $1" >&2; return 1 ;;
  esac
}
