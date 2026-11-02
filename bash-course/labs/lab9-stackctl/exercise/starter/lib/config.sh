# shellcheck shell=bash
# config.sh — the environment file is DATA. It is parsed line by line and
# checked against a whitelist; it is never sourced or eval'ed, so a line like
#   PORT=18080; rm -rf /
# is a validation error, not a command.

CONF_KEYS=(PORT PROJECT APP_DIR IMAGE_SERVE IMAGE_GATEWAY HEALTH_PATH HEALTH_BODY WAIT_TIMEOUT)

# parse_conf FILE  → fills the global associative array CONF; returns 2 on a bad line
parse_conf() {
  # TODO (LAB-09a)
  #   Read "$1" line by line (while IFS= read -r line || [[ -n "$line" ]]; do … done < "$1").
  #   Strip comments ("${line%%#*}") and trailing whitespace; skip empty lines.
  #   Require KEY=VALUE; split with "${line%%=*}" / "${line#*=}".
  #   Reject a key that is not ^[A-Z][A-Z_]*$ or not in CONF_KEYS (is_known_key) → err + return 2.
  #   Store CONF["$key"]="$val". Never source or eval the file.
  err "parse_conf: not implemented yet (see TASK.md)"; return 1
}

is_known_key() {
  local k
  for k in "${CONF_KEYS[@]}"; do [[ "$k" == "$1" ]] && return 0; done
  return 1
}

# validate_conf  → checks every required key and value shape; returns 2 on the first problem
validate_conf() {
  # TODO (LAB-09a)
  #   Every key in CONF_KEYS must be present and non-empty → otherwise err + return 2.
  #   PORT: digits only and 1024–65535.  PROJECT: ^[a-z][a-z0-9-]*$.  WAIT_TIMEOUT: digits.
  #   IMAGE_SERVE / IMAGE_GATEWAY: name:tag, optionally @sha256:<64 hex>.
  #   APP_DIR: a relative path with no spaces and no "..", and "$ROOT/$APP_DIR/Dockerfile.course" must exist.
  #   HEALTH_PATH: starts with "/", no spaces.  HEALTH_BODY: one line.
  #   Return 2 on the first problem, 0 when everything checks out.
  err "validate_conf: not implemented yet (see TASK.md)"; return 1
}

# load_conf  → parse + validate the selected environment (exit code of the first failure)
load_conf() {
  parse_conf "$CONF_FILE" || return $?
  validate_conf || return $?
}

# render_compose OUTDIR → writes OUTDIR/stack.yml and OUTDIR/gateway.conf from the
# templates and CONF. The bind-mount path inside the file always points at the APPLIED
# dir (.render/ENV) and the build context at $ROOT/APP_DIR, so a render made for
# plan/validate compares equal to the one `up` applied.
render_compose() {
  local out="$1" mount="$ROOT/.render/$ENV_NAME" app="$ROOT/${CONF[APP_DIR]}"
  mkdir -p "$out"
  sed -e "s|@PORT@|${CONF[PORT]}|g" \
      -e "s|@IMAGE_SERVE@|${CONF[IMAGE_SERVE]}|g" \
      -e "s|@IMAGE_GATEWAY@|${CONF[IMAGE_GATEWAY]}|g" \
      -e "s|@APP_DIR@|$app|g" \
      -e "s|@HEALTH_PATH@|${CONF[HEALTH_PATH]}|g" \
      -e "s|@RENDER_DIR@|$mount|g" \
      "$ROOT/compose/stack.yml.tmpl" > "$out/stack.yml"
  cp "$ROOT/compose/gateway.conf.tmpl" "$out/gateway.conf"
}

# cmd_validate — parse, validate, render to temp space, ask compose to parse it. No mutation.
cmd_validate() {
  local rc=0
  load_conf || rc=$?
  (( rc == 0 )) || return "$rc"
  render_compose "$WORK/validate"
  if ! drv_compose "${CONF[PROJECT]}" "$WORK/validate/stack.yml" config -q; then
    err "compose rejected the rendered file"; return 2
  fi
  info "ok: $ENV_NAME → project ${CONF[PROJECT]} on port ${CONF[PORT]} (serve ${CONF[IMAGE_SERVE]} built from ${CONF[APP_DIR]}/, gateway ${CONF[IMAGE_GATEWAY]}, health GET ${CONF[HEALTH_PATH]})"
  [[ "${CONF[IMAGE_GATEWAY]}" == *@sha256:* ]] || info "warning: IMAGE_GATEWAY is pinned by tag only; record its digest after the first pull (see RUNBOOK.md)"
  info "note: IMAGE_SERVE is built locally; record its image ID with tools/record-manifest.sh after the first up"
}
