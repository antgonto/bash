#!/usr/bin/env bash
# Push every scanner report to SecObserve (ch. 13). Env: SO_URL, SO_TOKEN, SO_PRODUCT.
set -euo pipefail
upload () {  # $1=parser  $2=file
  [ -f "$2" ] || { echo "skip $2 (missing)"; return 0; }
  curl -sf -X POST "$SO_URL/api/import/file_upload/" \
    -H "Authorization: APIToken $SO_TOKEN" \
    -F "product=$SO_PRODUCT" -F "parser_name=$1" -F "file=@$2" >/dev/null \
    && echo "uploaded $2 ($1)"
}
upload "Trivy"     trivy-fs.json
upload "Trivy"     trivy.json
upload "Semgrep"   semgrep.json
upload "Gitleaks"  gitleaks.json
upload "OWASP_ZAP" rapidast/zap.json
upload "SARIF"     nuclei.sarif
echo "SO-UPLOAD-DONE"
