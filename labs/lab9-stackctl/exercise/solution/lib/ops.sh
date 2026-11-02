# shellcheck shell=bash
# ops.sh — plan / up / check / status / logs / destroy, all scoped to one
# environment's compose project. Every mutating command runs under the
# environment's lock, after validation, and never touches other projects.

applied_dir() { printf '%s/.render/%s' "$ROOT" "$ENV_NAME"; }

# with_lock CMD... — one stackctl at a time per environment (flock -n: fail fast, never queue)
with_lock() {
  local lock="$ROOT/envs/$ENV_NAME.lock"
  exec 9>"$lock"
  if ! flock -n 9; then
    err "$ENV_NAME is locked by another stackctl run ($lock); try again later"
    return 1
  fi
  "$@"
}

running_services() {   # names of running services, one per line (may be empty)
  drv_compose "${CONF[PROJECT]}" "$1" ps --services --status running 2>/dev/null || true
}

# cmd_plan — desired (render now) vs applied (last up) vs running (compose ps). No mutation.
cmd_plan() {
  local applied; applied="$(applied_dir)"
  render_compose "$WORK/plan"
  info "plan for $ENV_NAME (project ${CONF[PROJECT]}):"
  info "  desired : port ${CONF[PORT]}, serve ${CONF[IMAGE_SERVE]} (from ${CONF[APP_DIR]}/), gateway ${CONF[IMAGE_GATEWAY]}, health GET ${CONF[HEALTH_PATH]} = '${CONF[HEALTH_BODY]}'"
  local drift="none"
  if [[ ! -f "$applied/stack.yml" ]]; then
    info "  applied : never applied in this checkout"; drift="new"
  elif ! diff -q "$applied/stack.yml" "$WORK/plan/stack.yml" >/dev/null \
       || ! diff -q "$applied/gateway.conf" "$WORK/plan/gateway.conf" >/dev/null; then
    info "  applied : differs from desired:"
    diff "$applied/stack.yml" "$WORK/plan/stack.yml" | sed 's/^/            /' || true
    diff "$applied/gateway.conf" "$WORK/plan/gateway.conf" | sed 's/^/            /' || true
    drift="changed"
  else
    info "  applied : identical to desired"
  fi
  local n; n="$(running_services "${applied}/stack.yml" | grep -c . || true)"
  info "  running : $n of 2 services (from compose ps)"
  if [[ "$drift" == new ]]; then
    info "  up would: create project ${CONF[PROJECT]} (2 services)"
  elif [[ "$drift" == changed ]]; then
    info "  up would: re-render and recreate the services whose definition changed"
  elif (( n < 2 )); then
    info "  up would: start the $(( 2 - n )) stopped service(s); no definition changes"
  else
    info "  up would: nothing — converged"
  fi
  info "  limits  : plan cannot predict the image build, pulls or health outcomes; only 'up' proves those"
}

# cmd_up — render to the applied dir and bring the project up, waiting for health
cmd_up() {
  local applied; applied="$(applied_dir)"
  render_compose "$applied"
  info "up: $ENV_NAME (project ${CONF[PROJECT]}, port ${CONF[PORT]}, wait ≤ ${CONF[WAIT_TIMEOUT]}s)"
  if ! drv_compose "${CONF[PROJECT]}" "$applied/stack.yml" up -d --wait --wait-timeout "${CONF[WAIT_TIMEOUT]}"; then
    err "up failed for $ENV_NAME; see: $PROG -e $ENV_NAME logs"; return 1
  fi
  info "up: done — $(running_services "$applied/stack.yml" | grep -c . || true) of 2 services running"
}

# cmd_check — GET HEALTH_PATH must equal HEALTH_BODY exactly; 3 on mismatch, 1 if unreachable
cmd_check() {
  local url="http://127.0.0.1:${CONF[PORT]}${CONF[HEALTH_PATH]}" got
  # "$( )" strips trailing newlines, which would make '{"status":"ok"}\n' pass as the exact body. The
  # printf x / ${got%x} idiom keeps the body byte-exact.
  if ! got="$(drv_http_get "$url" && printf x)"; then
    err "check: $url unreachable (is the stack up? try: $PROG -e $ENV_NAME status)"; return 1
  fi
  got="${got%x}"
  if [[ "$got" != "${CONF[HEALTH_BODY]}" ]]; then
    err "check: $url returned [$got], expected [${CONF[HEALTH_BODY]}]"; return 3
  fi
  info "check: $url → [$got] ok"
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
  local applied; applied="$(applied_dir)"
  if [[ "${CONFIRM_DESTROY:-}" != "$ENV_NAME" ]]; then
    err "destroy refused: set CONFIRM_DESTROY=$ENV_NAME to destroy project ${CONF[PROJECT]}"; return 2
  fi
  render_compose "$WORK/destroy"
  local file="$applied/stack.yml"; [[ -f "$file" ]] || file="$WORK/destroy/stack.yml"
  if ! drv_compose "${CONF[PROJECT]}" "$file" down -v; then
    err "destroy failed for ${CONF[PROJECT]}"; return 1
  fi
  rm -rf "$applied"
  info "destroy: project ${CONF[PROJECT]} removed (containers, network, volumes)"
}
