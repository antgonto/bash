# shellcheck shell=bash
# util.sh — logging, config, temp-file cleanup, input resolution.
# Sourced by bin/logsleuth and exercised directly by the labs.
# (These names are used by the sibling sourced files, so shellcheck's
# "appears unused" for a single file does not apply.)
# shellcheck disable=SC2034

LOGSLEUTH_VERSION="1.0.0"

# Colour only on a terminal and only when NO_COLOR is unset (so pipes stay clean).
if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then
  C_RED=$'\e[31m'; C_YEL=$'\e[33m'; C_GRN=$'\e[32m'; C_DIM=$'\e[2m'; C_OFF=$'\e[0m'
else
  C_RED=''; C_YEL=''; C_GRN=''; C_DIM=''; C_OFF=''
fi

log()  { printf '%s[logsleuth]%s %s\n' "$C_DIM" "$C_OFF" "$*" >&2; }
warn() { printf '%s[warn]%s %s\n'      "$C_YEL" "$C_OFF" "$*" >&2; }
# die "message" [exit-code]  — report on stderr and exit (default 1)
die()  { printf '%s[error]%s %s\n' "$C_RED" "$C_OFF" "$1" >&2; exit "${2:-1}"; }

trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; printf '%s' "$s"; }

# ---- configuration: parsed as data, never `source`d (a config file must not be
# able to run code) ----
TOP_N="${TOP_N:-10}"
BRUTE_THRESHOLD="${BRUTE_THRESHOLD:-10}"

load_config() {       # load_config <file> — silently ignores a missing file
  local f="$1" key val
  [[ -f "$f" ]] || return 0
  while IFS='=' read -r key val; do
    key="${key%%#*}"; key="$(trim "$key")"; val="$(trim "${val%%#*}")"
    [[ -z "$key" ]] && continue
    case "$key" in
      top_n)           if [[ "$val" =~ ^[0-9]+$ ]]; then TOP_N="$val"; else warn "config: top_n must be a number"; fi ;;
      brute_threshold) if [[ "$val" =~ ^[0-9]+$ ]]; then BRUTE_THRESHOLD="$val"; else warn "config: brute_threshold must be a number"; fi ;;
      *) warn "config: ignoring unknown key '$key'" ;;
    esac
  done < "$f"
}

# ---- temp files cleaned up on ANY exit (see the trap in bin/logsleuth) ----
# ONE private directory, created in the parent shell at startup. Every temp file
# lives inside it, so cleanup removes the lot with a single `rm -rf`. This also
# dodges a subtle bug: resolve_input runs inside a command substitution (a
# subshell), so a per-file array appended there would never reach the parent's
# trap — but files written under this shared dir persist on disk regardless.
_WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/logsleuth.XXXXXX")"
# An EXIT trap's status can become the script's, so cleanup ends with return 0.
cleanup() { [[ -n "${_WORKDIR:-}" ]] && rm -rf "$_WORKDIR"; return 0; }
mktempfile() { mktemp "$_WORKDIR/f.XXXXXX"; }

# resolve_input [FILE] — echo a readable path: the named file, or a temp copy of
# stdin (so the data can be scanned more than once). Dies if the file is unreadable.
resolve_input() {
  if [[ $# -ge 1 && -n "${1:-}" && "$1" != "-" ]]; then
    [[ -r "$1" ]] || die "cannot read log file: $1" 1
    printf '%s\n' "$1"
  else
    local t; t="$(mktempfile)"; cat > "$t"; printf '%s\n' "$t"
  fi
}
