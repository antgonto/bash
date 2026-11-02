# shellcheck shell=bash
# config.sh — the environment file is DATA. It is parsed line by line and
# checked against a whitelist; it is never sourced or eval'ed, so a line like
#   PORT=18080; rm -rf /
# is a validation error, not a command.

CONF_KEYS=(PORT PROJECT APP_DIR IMAGE_SERVE IMAGE_GATEWAY HEALTH_PATH HEALTH_BODY WAIT_TIMEOUT)

# parse_conf FILE  → fills the global associative array CONF; returns 2 on a bad line
parse_conf() {
  local file="$1" line key val n=0
  [[ -r "$file" ]] || { err "cannot read environment file: $file"; return 2; }
  while IFS= read -r line || [[ -n "$line" ]]; do
    n=$(( n + 1 ))
    line="${line%%#*}"                       # strip comments
    line="${line%"${line##*[![:space:]]}"}"  # strip trailing whitespace
    [[ -z "$line" ]] && continue
    if [[ "$line" != *=* ]]; then
      err "$file:$n: expected KEY=VALUE, got: $line"; return 2
    fi
    key="${line%%=*}"; val="${line#*=}"
    if [[ ! "$key" =~ ^[A-Z][A-Z_]*$ ]]; then
      err "$file:$n: bad key name: $key"; return 2
    fi
    if ! is_known_key "$key"; then
      err "$file:$n: unknown key: $key (allowed: ${CONF_KEYS[*]})"; return 2
    fi
    CONF["$key"]="$val"
  done < "$file"
}

is_known_key() {
  local k
  for k in "${CONF_KEYS[@]}"; do [[ "$k" == "$1" ]] && return 0; done
  return 1
}

# validate_conf  → checks every required key and value shape; returns 2 on the first problem
validate_conf() {
  local k
  for k in "${CONF_KEYS[@]}"; do
    [[ -n "${CONF[$k]:-}" ]] || { err "$CONF_FILE: missing required key: $k"; return 2; }
  done
  [[ "${CONF[PORT]}" =~ ^[0-9]+$ ]] || { err "PORT must be a number, got: ${CONF[PORT]}"; return 2; }
  (( CONF[PORT] >= 1024 && CONF[PORT] <= 65535 )) || { err "PORT must be 1024–65535, got: ${CONF[PORT]}"; return 2; }
  [[ "${CONF[PROJECT]}" =~ ^[a-z][a-z0-9-]*$ ]] || { err "PROJECT must be lowercase letters, digits, dashes, got: ${CONF[PROJECT]}"; return 2; }
  [[ "${CONF[WAIT_TIMEOUT]}" =~ ^[0-9]+$ ]] || { err "WAIT_TIMEOUT must be a number of seconds"; return 2; }
  for k in IMAGE_SERVE IMAGE_GATEWAY; do
    [[ "${CONF[$k]}" =~ ^[a-z0-9][a-z0-9._/-]*:[A-Za-z0-9._-]+(@sha256:[0-9a-f]{64})?$ ]] \
      || { err "$k must be name:tag or name:tag@sha256:<64 hex>, got: ${CONF[$k]}"; return 2; }
  done
  [[ "${CONF[APP_DIR]}" =~ ^[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)*$ ]] \
    || { err "APP_DIR must be a relative path inside the tool (no spaces, no ..), got: ${CONF[APP_DIR]}"; return 2; }
  [[ -f "$ROOT/${CONF[APP_DIR]}/Dockerfile.course" ]] \
    || { err "APP_DIR ${CONF[APP_DIR]}/ has no Dockerfile.course — is the fraud-clf app copy in place?"; return 2; }
  [[ "${CONF[HEALTH_PATH]}" =~ ^/[A-Za-z0-9._/-]*$ ]] || { err "HEALTH_PATH must start with / and contain no spaces, got: ${CONF[HEALTH_PATH]}"; return 2; }
  [[ "${CONF[HEALTH_BODY]}" != *[$'\n\r']* ]] || { err "HEALTH_BODY must be one line"; return 2; }
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
