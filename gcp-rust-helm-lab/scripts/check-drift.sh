#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$ROOT_DIR/infra/terraform"
TFVARS="${TFVARS:-$TF_DIR/terraform.tfvars}"

terraform -chdir="$TF_DIR" init -input=false

set +e
terraform -chdir="$TF_DIR" plan -detailed-exitcode -input=false -var-file="$TFVARS"
status=$?
set -e

case "$status" in
  0)
    echo "Terraform drift check passed: no changes detected."
    ;;
  2)
    echo "WARNING: Terraform drift or unapplied configuration changes detected."
    echo "Review the plan above before relying on this environment."
    ;;
  *)
    echo "Terraform drift check failed with exit code $status." >&2
    exit "$status"
    ;;
esac

exit "$status"
