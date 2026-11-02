#!/usr/bin/env bash
# Deploy the verified digest to $KUBE_CONTEXT (test=staging cluster, prod=production cluster).
set -euo pipefail
source "$(dirname "$0")/versions.env"
: "${KUBE_CONTEXT:=staging}" ; : "${APP_ENV:=test}"
DIGEST="$(cat image.digest)"
echo "== pre-deploy: verify signature + attestations =="
cosign verify $COSIGN_VERIFY_FLAGS --key cosign.pub "$IMAGE@$DIGEST" >/dev/null && echo "signature OK"
cosign verify-attestation $COSIGN_VERIFY_FLAGS --key cosign.pub --type cyclonedx "$IMAGE@$DIGEST" >/dev/null && echo "SBOM attestation OK"
echo "== deploy to $KUBE_CONTEXT ($APP_ENV) =="
sed -e "s|__IMAGE__|$IMAGE@$DIGEST|" -e "s|__ENV__|$APP_ENV|" -e "s|__VERSION__|${GIT_SHA:-unknown}|" k8s/serve.yaml \
  | kubectl --context "$KUBE_CONTEXT" apply -f -
kubectl --context "$KUBE_CONTEXT" -n apps rollout status deploy/serve --timeout=180s
echo "== smoke tests =="
API_URL="${API_URL:-https://staging.secmlops.com}" pytest tests/smoke -q
echo "DEPLOY-PASS ($KUBE_CONTEXT)"
