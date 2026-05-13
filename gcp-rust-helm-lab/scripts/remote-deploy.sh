#!/usr/bin/env bash
set -euo pipefail

IMAGE_REPOSITORY="${IMAGE_REPOSITORY:-rust-api}"
IMAGE_TAG="${IMAGE_TAG:?IMAGE_TAG is required}"
RELEASE_NAME="${RELEASE_NAME:-rust-api}"
NAMESPACE="${NAMESPACE:-lab-rust}"
IMAGE_ARCHIVE="${IMAGE_ARCHIVE:-/tmp/rust-api-image.tar}"
CHART_DIR="${CHART_DIR:-/tmp/rust-api-chart}"

until sudo k3s kubectl get nodes >/dev/null 2>&1; do
  echo "Waiting for k3s to become ready..."
  sleep 5
done

if ! command -v helm >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

sudo k3s ctr --namespace k8s.io images import "$IMAGE_ARCHIVE"

helm upgrade --install "$RELEASE_NAME" "$CHART_DIR" \
  --kubeconfig /etc/rancher/k3s/k3s.yaml \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --set image.repository="$IMAGE_REPOSITORY" \
  --set image.tag="$IMAGE_TAG" \
  --wait \
  --timeout 180s

sudo k3s kubectl get pods,svc -n "$NAMESPACE"
