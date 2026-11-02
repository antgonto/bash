# shellcheck shell=bash
# ops.sh — plan / up / check / status / logs / destroy, all scoped to one
# environment's compose project. Every mutating command runs under the
# environment's lock, after validation, and never touches other projects.

applied_dir() { printf '%s/.render/%s' "$ROOT" "$ENV_NAME"; }

# with_lock CMD... — one stackctl at a time per environment (flock -n: fail fast, never queue)
with_lock() {
  # TODO (LAB-09b)
  #   lock="$ROOT/envs/$ENV_NAME.lock"; exec 9>"$lock"; flock -n 9 || { err "…locked…"; return 1; }
  #   then run the command: "$@"
  err "with_lock: not implemented yet (see TASK.md)"; return 1
}

running_services() {   # names of running services, one per line (may be empty)
  drv_compose "${CONF[PROJECT]}" "$1" ps --services --status running 2>/dev/null || true
}

# cmd_plan — desired (render now) vs applied (last up) vs running (compose ps). No mutation.
cmd_plan() {
  # TODO (LAB-09b)
  #   applied="$(applied_dir)"; render_compose "$WORK/plan"   (a temp render — plan must not touch .render/)
  #   Print: desired (from CONF); applied (never applied / identical / differs — diff stack.yml AND gateway.conf of the two renders);
  #   running (running_services "$applied/stack.yml" | grep -c .); then exactly one "up would: …" line:
  #     "up would: create …"  |  "up would: re-render and recreate …"  |  "up would: start …"  |  "up would: nothing — converged"
  #   and a "limits" line saying plan cannot predict the build, pulls or health. Make NO compose up/down call.
  err "cmd_plan: not implemented yet (see TASK.md)"; return 1
}

# cmd_up — render to the applied dir and bring the project up, waiting for health
cmd_up() {
  # TODO (LAB-09b)
  #   applied="$(applied_dir)"; render_compose "$applied"
  #   drv_compose "${CONF[PROJECT]}" "$applied/stack.yml" up -d --wait --wait-timeout "${CONF[WAIT_TIMEOUT]}"
  #   failure → err (point at: $PROG -e $ENV_NAME logs) + return 1; success → print how many services run.
  err "cmd_up: not implemented yet (see TASK.md)"; return 1
}

# cmd_check — GET HEALTH_PATH must equal HEALTH_BODY exactly; 3 on mismatch, 1 if unreachable
cmd_check() {
  # TODO (LAB-09a)
  #   url="http://127.0.0.1:${CONF[PORT]}${CONF[HEALTH_PATH]}"; fetch it with drv_http_get (through the gateway).
  #   Unreachable → err + return 1.  Body ≠ "${CONF[HEALTH_BODY]}" byte-for-byte → err (show got/expected) + return 3.
  #   Remember "$( )" strips trailing newlines ('{"status":"ok"}\n' is NOT the body): capture with  got="$(drv_http_get "$url" && printf x)"; got="${got%x}".
  #   On success print one line and return 0.
  err "cmd_check: not implemented yet (see TASK.md)"; return 1
}

cmd_status() {
  local applied; applied="$(applied_dir)"
  if [[ ! -f "$applied/stack.yml" ]]; then info "status: $ENV_NAME never applied in this checkout"; return 0; fi
  local list; list="$(running_services "$applied/stack.yml")"
  if [[ -z "$list" ]]; then info "status: $ENV_NAME — no services running"
  else info "status: $ENV_NAME — running:"; printf '%s\n' "$list" | sed 's/^/  /'; fi
}

cmd_logs() {
  local applied; applied="$(applied_dir)"
  [[ -f "$applied/stack.yml" ]] || { err "logs: $ENV_NAME never applied"; return 1; }
  drv_compose "${CONF[PROJECT]}" "$applied/stack.yml" logs --tail "${STACKCTL_LOG_LINES:-50}"
}

# cmd_destroy — refuses unless CONFIRM_DESTROY names this exact environment;
# removes only this project's containers, network and volumes. Never prunes globally.
cmd_destroy() {
  # TODO (LAB-09b)
  #   [[ "${CONFIRM_DESTROY:-}" == "$ENV_NAME" ]] || { err "destroy refused: set CONFIRM_DESTROY=$ENV_NAME …"; return 2; }
  #   drv_compose "${CONF[PROJECT]}" "$(applied_dir)/stack.yml" down -v   (scoped to THIS project; never `docker system prune`)
  #   then rm -rf "$(applied_dir)" and print one line.
  err "cmd_destroy: not implemented yet (see TASK.md)"; return 1
}
