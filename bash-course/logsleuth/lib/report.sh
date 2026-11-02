# shellcheck shell=bash
# report.sh — the subcommands. Each resolves its input (file or stdin), then
# reports. These are the functions the test suite (Lab 8) unit-tests.

cmd_summary() {
  local f; f="$(resolve_input "$@")"
  local total uniq_ips
  total="$(wc -l < "$f")"
  uniq_ips="$(field_ip "$f" | sort -u | grep -c .)"
  printf '%sSummary%s  %s\n' "$C_GRN" "$C_OFF" "${1:-<stdin>}"
  printf '  requests     %s\n' "$(trim "$total")"
  printf '  unique IPs   %s\n' "$uniq_ips"
  printf '  by class:\n'
  local cls n
  while read -r cls n; do printf '    %-4s %s\n' "$cls" "$n"; done < <(status_classes "$f")
}

cmd_top() {
  # FIELD comes from -f (ip|path|status); default ip. TOP_N from config/-n.
  local field="${FIELD:-ip}" col
  case "$field" in
    ip) col=1 ;; path) col=7 ;; status) col=9 ;;
    *) die "unknown -f field: $field (use ip|path|status)" 2 ;;
  esac
  local f; f="$(resolve_input "$@")"
  printf '%sTop %s %s%s\n' "$C_GRN" "$TOP_N" "$field" "$C_OFF"
  count_col "$f" "$col" "$TOP_N" | awk '{printf "  %6s  %s\n", $1, $2}'
}

cmd_errors() {
  local f; f="$(resolve_input "$@")"
  local c4 c5
  c4="$(field_status "$f" | grep -c '^4' || true)"
  c5="$(field_status "$f" | grep -c '^5' || true)"
  printf '%sErrors%s  4xx=%s  5xx=%s\n' "$C_GRN" "$C_OFF" "$c4" "$c5"
  printf '  worst paths (4xx/5xx):\n'
  awk '$9 ~ /^[45][0-9][0-9]$/ {print $7}' "$f" | sort | uniq -c | sort -rn | head -n "$TOP_N" \
    | awk '{printf "    %6s  %s\n", $1, $2}'
}

cmd_bruteforce() {
  local f; f="$(resolve_input "$@")"
  # count failed logins per source IP in a pure-bash associative array, then
  # flag any IP at or above the threshold.
  declare -A fails
  local ip n found=0
  while read -r ip; do
    [[ -n "$ip" ]] || continue
    # `:-0` defaults the as-yet-unset key to 0, which is required under `set -u`
    # (a bare (( ++fails[ip] )) on an unset key would abort as "unbound variable").
    fails["$ip"]=$(( ${fails["$ip"]:-0} + 1 ))
  done < <(failed_login_ips "$f")

  printf '%sBrute-force scan%s  (threshold %s failed logins)\n' "$C_GRN" "$C_OFF" "$BRUTE_THRESHOLD"
  # Read the sorted counts via process substitution so the loop runs in THIS
  # shell and `found` survives (a pipe would run it in a subshell and lose it).
  while read -r ip n; do
    if (( n >= BRUTE_THRESHOLD )); then
      printf '  %s%-15s%s  %s failed\n' "$C_RED" "$ip" "$C_OFF" "$n"
      found=1
    fi
  done < <(for ip in "${!fails[@]}"; do printf '%s %s\n' "$ip" "${fails[$ip]}"; done | sort -k2 -rn)

  if (( found )); then return 3; fi
  printf '  none above threshold\n'
}
