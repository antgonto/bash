#!/usr/bin/env bash
# make_logs.sh — write deterministic fixture logs the labs analyze. Exact,
# documented counts so every autograder can assert precise numbers.
#
#   ./make_logs.sh <output-dir>      # writes access.log, auth.log, EXPECTED.txt
#
# The logs come from the SecMLOps program's project: the fraud-clf prediction
# API (FastAPI `serve`, /api/health and /api/predict) behind its gateway on
# staging.secmlops.com, and the sshd log of the Course 1 lab VM (lab01).
#
# access.log  (Nginx Combined Log Format, the gateway), 140 requests:
#   10.0.0.1      50 x 200   (GET /api/health — the cluster's readiness probes)
#   10.0.0.2      20 x 200   (GET /docs) + 10 x 404 (GET /api/v2/predict — wrong version)
#   203.0.113.9   40 x 401   (POST /api/predict without a token — unauthenticated probing)
#   198.51.100.7  15 x 200   (POST /api/predict) + 5 x 500 (bad payloads)
#   => top IP 10.0.0.1 (50); status 200=85 404=10 401=40 500=5; 4xx=50 5xx=5
#
# auth.log  (sshd syslog lines from the lab VM lab01):
#   203.0.113.9   25 Failed password   (brute force)
#   198.51.100.23  4 Failed password
#   192.0.2.5      2 Failed + 1 Accepted
#   192.0.2.10     1 Accepted
#   => failed-by-ip: 203.0.113.9=25, 198.51.100.23=4, 192.0.2.5=2 ; brute(>=10)=203.0.113.9
set -euo pipefail
OUT="${1:?usage: make_logs.sh <output-dir>}"
mkdir -p "$OUT"
ACCESS="$OUT/access.log"; AUTH="$OUT/auth.log"
: > "$ACCESS"; : > "$AUTH"

UA='"python-requests/2.19.1"'
# a deterministic clock: start at a fixed second and increment
secs=0
ts() {  # access-log timestamp, advancing
  local h=$((13 + secs/3600 % 24)) m=$((secs/60 % 60)) s=$((secs % 60)); secs=$((secs+7))
  printf '[16/Oct/2026:%02d:%02d:%02d -0500]' "$h" "$m" "$s"
}
acc() { # ip method path proto status bytes
  printf '%s - - %s "%s %s %s" %s %s "-" %s\n' "$1" "$(ts)" "$2" "$3" "$4" "$5" "$6" "$UA" >> "$ACCESS"
}

i=0; while [ "$i" -lt 50 ]; do acc 10.0.0.1 GET /api/health      HTTP/1.1 200 512; i=$((i+1)); done
i=0; while [ "$i" -lt 20 ]; do acc 10.0.0.2 GET /docs            HTTP/1.1 200 420; i=$((i+1)); done
i=0; while [ "$i" -lt 10 ]; do acc 10.0.0.2 GET /api/v2/predict  HTTP/1.1 404 153; i=$((i+1)); done
i=0; while [ "$i" -lt 40 ]; do acc 203.0.113.9 POST /api/predict HTTP/1.1 401 173; i=$((i+1)); done
i=0; while [ "$i" -lt 15 ]; do acc 198.51.100.7 POST /api/predict HTTP/1.1 200 998; i=$((i+1)); done
i=0; while [ "$i" -lt  5 ]; do acc 198.51.100.7 POST /api/predict HTTP/1.1 500 0; i=$((i+1)); done

# ---- auth.log ----
amin=0
authln() { # "message"
  local M=$((amin/60 % 60)) S=$((amin % 60)); amin=$((amin+3))
  printf 'Oct 16 13:%02d:%02d lab01 %s\n' "$M" "$S" "$1" >> "$AUTH"
}
i=0; while [ "$i" -lt 25 ]; do authln "sshd[2001]: Failed password for invalid user admin from 203.0.113.9 port 44512 ssh2"; i=$((i+1)); done
i=0; while [ "$i" -lt  4 ]; do authln "sshd[2002]: Failed password for root from 198.51.100.23 port 51000 ssh2"; i=$((i+1)); done
authln "sshd[2003]: Failed password for deploy from 192.0.2.5 port 40001 ssh2"
authln "sshd[2003]: Failed password for deploy from 192.0.2.5 port 40002 ssh2"
authln "sshd[2003]: Accepted password for deploy from 192.0.2.5 port 40003 ssh2"
authln "sshd[2004]: Accepted password for mlops from 192.0.2.10 port 40100 ssh2"

cat > "$OUT/EXPECTED.txt" <<'EOF'
access.log: 140 requests; top IP 10.0.0.1 (50); status 200=85 404=10 401=40 500=5; 4xx=50 5xx=5
auth.log: failed-by-ip 203.0.113.9=25 198.51.100.23=4 192.0.2.5=2; accepted 2; brute(>=10)=203.0.113.9
EOF
echo "wrote $ACCESS ($(wc -l < "$ACCESS") lines) and $AUTH ($(wc -l < "$AUTH") lines)"
