#!/usr/bin/env bash
set -euo pipefail

IMAGE_REPOSITORY="${IMAGE_REPOSITORY:-rust-api}"
IMAGE_TAG="${IMAGE_TAG:?IMAGE_TAG is required}"
RELEASE_NAME="${RELEASE_NAME:-rust-api}"
NAMESPACE="${NAMESPACE:-lab-rust}"
IMAGE_ARCHIVE="${IMAGE_ARCHIVE:-/tmp/rust-api-image.tar}"
CHART_DIR="${CHART_DIR:-/tmp/rust-api-chart}"
K3S_READY_TIMEOUT_SECONDS="${K3S_READY_TIMEOUT_SECONDS:-300}"

wait_for_k3s() {
  local waited=0

  until sudo k3s kubectl --request-timeout=10s get --raw=/readyz >/dev/null 2>&1; do
    if [[ "$waited" -ge "$K3S_READY_TIMEOUT_SECONDS" ]]; then
      echo "Timed out waiting for k3s API readiness after ${K3S_READY_TIMEOUT_SECONDS}s." >&2
      sudo systemctl --no-pager --full status k3s || true
      exit 1
    fi

    echo "Waiting for k3s API to become ready..."
    sleep 5
    waited=$((waited + 5))
  done
}

wait_for_k3s

if ! command -v helm >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

sudo k3s ctr --namespace k8s.io images import "$IMAGE_ARCHIVE"

# On very small instances, importing and unpacking image layers can briefly
# starve the k3s API server. Wait again before asking Helm to connect.
wait_for_k3s

helm upgrade --install "$RELEASE_NAME" "$CHART_DIR" \
  --kubeconfig /etc/rancher/k3s/k3s.yaml \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --set image.repository="$IMAGE_REPOSITORY" \
  --set image.tag="$IMAGE_TAG" \
  --wait \
  --timeout 180s

sudo k3s kubectl get pods,svc -n "$NAMESPACE"
