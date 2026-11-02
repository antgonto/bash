#!/usr/bin/env bash
# "Is my computer ready for Course 2?" — Ubuntu / macOS / Git Bash on Windows.
set -u; fail=0; warn=0
ok(){ printf '  ok    %-24s %s\n' "$1" "$2"; }; warnf(){ printf '  WARN  %-24s %s\n' "$1" "$2"; warn=$((warn+1)); }; failf(){ printf '  FAIL  %-24s %s\n' "$1" "$2"; fail=$((fail+1)); }
PY=$(command -v python3 || command -v python || true)
echo "== Python (the labs' scripts)"
if [ -n "$PY" ]; then v=$($PY -c 'import sys;print("%d.%d"%sys.version_info[:2])'); $PY -c 'import sys;sys.exit(0 if sys.version_info>=(3,12) else 1)' && ok "python" "$v ($PY)" || failf "python" "$v — need 3.12+ (Course 1 Laptop toolkit)"; else failf "python" "not found"; fi
[ -n "$PY" ] && $PY -c "import sklearn, pandas, numpy, pandera, safetensors, fastapi" 2>/dev/null && ok "python packages" "requirements installed" || warnf "python packages" "not installed yet — Module 0 step 2 runs pip install"
echo "== Tools"
command -v git >/dev/null && ok "git" "$(git --version | awk '{print $3}')" || failf "git" "not installed"
command -v cosign >/dev/null && ok "cosign" "$(cosign version 2>&1 | grep -oE 'v[0-9.]+' | head -1)" || warnf "cosign" "not on the laptop — needed from Lab 6.1; installed on the VM already"
command -v kubectl >/dev/null && ok "kubectl" "present" || warnf "kubectl" "not on the laptop — needed from Lab 9.1"
command -v docker >/dev/null && ok "docker" "present" || warnf "docker" "not on the laptop — only Lab 7.1 builds locally; the VM has Docker"
echo "== The lab from Course 1"
if curl -s --max-time 4 http://mlflow.secmlops.com:5000/health >/dev/null 2>&1; then ok "lab VM" "mlflow.secmlops.com answers"; else warnf "lab VM" "not reachable — fine for Modules -1 and 0; Labs need it (Course 1: make up + hosts line)"; fi
echo "== Files"
[ -f gen_data.py ] && [ -f train.py ] && ok "reference app" "you're in secmlops-app" || warnf "reference app" "run this from the unpacked secmlops-app folder"
echo; if [ $fail -gt 0 ]; then echo "RESULT: $fail problem(s) — see FAIL lines."; exit 1; elif [ $warn -gt 0 ]; then echo "RESULT: ready for Modules -1 and 0, with $warn note(s) for later labs."; else echo "RESULT: ready for the whole course."; fi
