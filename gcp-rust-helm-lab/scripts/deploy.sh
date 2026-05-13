#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$ROOT_DIR/infra/terraform"
API_DIR="$ROOT_DIR/apps/api"
CHART_DIR="$ROOT_DIR/deploy/helm/rust-api"
TFVARS="${TFVARS:-$TF_DIR/terraform.tfvars}"

IMAGE_REPOSITORY="${IMAGE_REPOSITORY:-rust-api}"
IMAGE_TAG="${IMAGE_TAG:-$(date +%Y%m%d%H%M%S)}"
RELEASE_NAME="${RELEASE_NAME:-rust-api}"
NAMESPACE="${NAMESPACE:-lab-rust}"
REQUIRE_NO_DRIFT="${REQUIRE_NO_DRIFT:-false}"
REQUIRE_CLEAN_GIT="${REQUIRE_CLEAN_GIT:-false}"

echo "Checking Git working tree..."
if git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git_status="$(git -C "$ROOT_DIR" status --short)"

  if [[ -n "$git_status" ]]; then
    echo "WARNING: Git working tree has uncommitted changes:"
    echo "$git_status"

    if [[ "$REQUIRE_CLEAN_GIT" == "true" ]]; then
      echo "Refusing to deploy because REQUIRE_CLEAN_GIT=true and the working tree is dirty." >&2
      exit 3
    fi
  else
    echo "Git working tree is clean."
  fi
else
  echo "WARNING: $ROOT_DIR is not inside a Git working tree; skipping Git cleanliness check."
fi

echo "Checking Terraform drift before deployment..."
set +e
TFVARS="$TFVARS" "$ROOT_DIR/scripts/check-drift.sh"
drift_status=$?
set -e

if [[ "$drift_status" -eq 2 && "$REQUIRE_NO_DRIFT" == "true" ]]; then
  echo "Refusing to deploy because REQUIRE_NO_DRIFT=true and Terraform reported changes." >&2
  exit 2
fi

VM_NAME="$(terraform -chdir="$TF_DIR" output -raw vm_name)"
VM_ZONE="$(terraform -chdir="$TF_DIR" output -raw vm_zone)"
SERVICE_URL="$(terraform -chdir="$TF_DIR" output -raw service_url)"
IMAGE_ARCHIVE="/tmp/${IMAGE_REPOSITORY}-${IMAGE_TAG}.tar"

echo "Building linux/amd64 image ${IMAGE_REPOSITORY}:${IMAGE_TAG}..."
docker buildx build --platform linux/amd64 --load -t "${IMAGE_REPOSITORY}:${IMAGE_TAG}" "$API_DIR"
docker save "${IMAGE_REPOSITORY}:${IMAGE_TAG}" -o "$IMAGE_ARCHIVE"

echo "Copying image, Helm chart, and remote deploy helper to ${VM_NAME}..."
gcloud compute scp "$IMAGE_ARCHIVE" "${VM_NAME}:/tmp/rust-api-image.tar" --zone "$VM_ZONE" --tunnel-through-iap
gcloud compute ssh "$VM_NAME" --zone "$VM_ZONE" --tunnel-through-iap --command "rm -rf /tmp/rust-api-chart /tmp/remote-deploy.sh"
gcloud compute scp --recurse "$CHART_DIR" "${VM_NAME}:/tmp/rust-api-chart" --zone "$VM_ZONE" --tunnel-through-iap
gcloud compute scp "$ROOT_DIR/scripts/remote-deploy.sh" "${VM_NAME}:/tmp/remote-deploy.sh" --zone "$VM_ZONE" --tunnel-through-iap

echo "Deploying Helm release ${RELEASE_NAME} to k3s..."
gcloud compute ssh "$VM_NAME" --zone "$VM_ZONE" --tunnel-through-iap --command "chmod +x /tmp/remote-deploy.sh && IMAGE_REPOSITORY='${IMAGE_REPOSITORY}' IMAGE_TAG='${IMAGE_TAG}' RELEASE_NAME='${RELEASE_NAME}' NAMESPACE='${NAMESPACE}' /tmp/remote-deploy.sh"

echo
echo "Deployment complete."
echo "Test it with:"
echo "curl ${SERVICE_URL}/dummy"
echo "curl ${SERVICE_URL}/healthz"
