#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$ROOT_DIR/infra/terraform"
TFVARS="${TFVARS:-$TF_DIR/terraform.tfvars}"

terraform -chdir="$TF_DIR" init -input=false
terraform -chdir="$TF_DIR" apply -input=false -var-file="$TFVARS"

echo
terraform -chdir="$TF_DIR" output
