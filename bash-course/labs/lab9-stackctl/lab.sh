#!/usr/bin/env bash
# Lab 9 walkthrough — infrastructure from bash: the six habits stackctl is built
# on, each shown in isolation with no Docker daemon and no reference solution:
#   1 config is data (parse, never source)   4 idempotency (re-run converges)
#   2 validate → plan → apply (plan is pure) 5 one operator at a time (flock -n)
#   3 exact health bodies                    6 destroy needs a named confirmation
# shellcheck source=../_lib.sh
source "$(dirname "$0")/../_lib.sh"
W="$(lab_workdir lab9)"

echo "== 1. a config file is data =="
printf 'PORT=18080\nPROJECT=fraudclf-demo\nNOTE=hello; touch %s/pwned\n' "$W" > "$W/evil.conf"
# shellcheck disable=SC1091  # the point is that this file is data, not code
( set +e; cd "$W" && source ./evil.conf >/dev/null 2>&1 )     # the WRONG way, in a subshell
check "sourcing the conf ran the command hidden in a value" test -e "$W/pwned"
rm -f "$W/pwned"
declare -A C=()
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"; [[ -z "$line" ]] && continue
  C["${line%%=*}"]="${line#*=}"
done < "$W/evil.conf"
check "parsing the same file ran nothing" test ! -e "$W/pwned"
is_eq "…and the value is just a string" "${C[NOTE]}" "hello; touch $W/pwned"
is_eq "PORT is read as data" "${C[PORT]}" "18080"
bad="80a8"; [[ "$bad" =~ ^[0-9]+$ ]] && (( bad >= 1024 && bad <= 65535 )) && r=valid || r=rejected
is_eq "a non-numeric PORT is rejected before anything runs" "$r" "rejected"

echo "== 2. plan is pure; apply mutates =="
calls="$W/calls.log"; : > "$calls"
driver() { printf '%s\n' "$*" >> "$calls"; [[ "$1" == up ]] && touch "$W/running"; return 0; }
plan()  { if [[ -e "$W/running" ]]; then echo "up would: nothing — converged"; else echo "up would: create 2 services"; fi; }
apply() { plan >/dev/null; driver up -d --wait; }
out="$(plan)"
is_eq "plan on a fresh state describes a change" "$out" "up would: create 2 services"
is_eq "plan made no driver call" "$(wc -l < "$calls")" "0"
apply
is_eq "apply made exactly one up call" "$(grep -c '^up ' "$calls")" "1"

echo "== 3. and 4. re-running converges =="
apply
is_eq "a second apply is harmless (same desired state)" "$(plan)" "up would: nothing — converged"
want='{"status":"ok"}'
body="$(printf '%s\n' "$want"; printf x)"; body="${body%x}"
[[ "$body" == "$want" ]] && r=same || r=different
is_eq "the body plus a newline is not the body when you keep the bytes (printf x trick)" "$r" "different"
body2="$(printf '%s\n' "$want")"
[[ "$body2" == "$want" ]] && r=same || r=different
is_eq "…but plain \$( ) silently drops the newline" "$r" "same"

echo "== 5. one operator per environment =="
( exec 9>"$W/test.lock"; flock 9; sleep 2 ) & holder=$!; sleep 0.2
( exec 9>"$W/test.lock"; flock -n 9 ) && r=acquired || r=busy
is_eq "flock -n fails fast while another holder exists" "$r" "busy"
( exec 9>"$W/prod.lock"; flock -n 9 ) && r=acquired || r=busy
is_eq "a different environment's lock is independent" "$r" "acquired"
wait "$holder"

echo "== 6. destroy needs the environment's name =="
destroy() { [[ "${CONFIRM_DESTROY:-}" == "$1" ]] || return 2; driver down -v; }
destroy test; is_eq "no confirmation → 2, nothing removed" "$?:$(grep -c down "$calls")" "2:0"
CONFIRM_DESTROY=prod destroy test; is_eq "wrong environment → 2" "$?" "2"
CONFIRM_DESTROY=test destroy test; is_eq "right environment → down -v" "$?:$(grep -c '^down -v$' "$calls")" "0:1"
is_eq "and never a prune" "$(grep -c prune "$calls")" "0"

summary lab9
