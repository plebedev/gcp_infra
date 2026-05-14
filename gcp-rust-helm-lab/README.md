# GCP Rust Helm Lab

This is a compact end-to-end lab for testing a realistic deployment flow:

1. Terraform creates one public `e2-micro` VM in GCP.
2. The VM installs k3s, a lightweight Kubernetes distribution.
3. A Rust API is built into a container image.
4. The image is copied to the VM and imported into k3s containerd.
5. Helm deploys the API to the VM's Kubernetes cluster.
6. The deployment script checks Terraform drift before deploying and warns if drift is detected.

It is intentionally small, but the folder layout mirrors a production-ish separation between app code, infrastructure code, Helm packaging, and deployment automation.

## Layout

```text
gcp-rust-helm-lab/
├── apps/
│   └── api/
│       ├── Cargo.toml
│       ├── Dockerfile
│       └── src/main.rs
├── deploy/
│   └── helm/rust-api/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── infra/
│   └── terraform/
│       ├── compute.tf
│       ├── firewall.tf
│       ├── network.tf
│       └── ...
└── scripts/
    ├── apply-infra.sh
    ├── check-drift.sh
    ├── deploy.sh
    └── destroy.sh
```

## What Terraform Creates

- A custom VPC: `lab-rust-vpc`
- A subnet: `lab-rust-subnet`
- Firewall rules for:
  - SSH on TCP 22 from Google IAP TCP forwarding only
  - public web traffic on TCP 80 and 443
- One Debian 12 `e2-micro` VM: `lab-rust-vm`
- An ephemeral public IP address on the VM
- A startup script that installs k3s with Traefik disabled, leaving port 80 available for this chart's service

This lab does not create GKE, Cloud NAT, load balancers, databases, GPUs, managed instance groups, or static IPs.

`e2-micro` keeps the lab cheap, but it is marginal for k3s. During image import, containerd can briefly starve the Kubernetes API server and cause slow `kubectl` responses or Helm TLS timeouts. If you want a smoother end-to-end test, use:

```hcl
machine_type = "e2-small"
```

## API

The Rust service exposes:

- `GET /healthz`
- `GET /dummy`

Example response:

```json
{
  "message": "dummy thing",
  "service": "rust-api",
  "status": "ok"
}
```

## Prerequisites

Install locally:

- `gcloud`
- `terraform`
- `docker` with Buildx support

Authenticate:

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project PROJECT_ID
```

## Configure

Create your Terraform variables file:

```bash
cd gcp-rust-helm-lab
cp infra/terraform/terraform.tfvars.example infra/terraform/terraform.tfvars
```

Edit `infra/terraform/terraform.tfvars`:

```hcl
project_id = "your-gcp-project-id"
```

By default, SSH is not exposed directly to the public internet. The VM has a public IP for web traffic, but SSH is allowed only from Google's IAP TCP forwarding range:

```hcl
iap_ssh_source_ranges = ["35.235.240.0/20"]
```

Public web traffic is controlled separately:

```hcl
web_source_ranges = ["0.0.0.0/0"]
```

## Apply Infrastructure

```bash
./scripts/apply-infra.sh
```

Wait a minute or two after apply for k3s to finish installing.

## Deploy The Service

```bash
./scripts/deploy.sh
```

Before deploying, the script runs:

```bash
terraform -chdir=infra/terraform plan -detailed-exitcode
```

If Terraform returns exit code `2`, the script prints a drift warning. It continues by default so you can still test the app, but you should inspect the plan before trusting the environment. To make drift block deployment:

```bash
REQUIRE_NO_DRIFT=true ./scripts/deploy.sh
```

The deploy script also checks whether the Git working tree is dirty. It warns by default and prints `git status --short`. To make uncommitted changes block deployment:

```bash
REQUIRE_CLEAN_GIT=true ./scripts/deploy.sh
```

## Test End To End

Get the public URL:

```bash
terraform -chdir=infra/terraform output service_url
```

Call the API:

```bash
curl "$(terraform -chdir=infra/terraform output -raw service_url)/dummy"
curl "$(terraform -chdir=infra/terraform output -raw service_url)/healthz"
```

You should receive JSON from the Rust service through the Helm deployment running on k3s.

## SSH And Inspect Kubernetes

SSH to the VM:

```bash
gcloud compute ssh lab-rust-vm --zone us-east1-b --tunnel-through-iap
```

Check Kubernetes:

```bash
sudo k3s kubectl get nodes
sudo k3s kubectl get pods -n lab-rust
sudo k3s kubectl get svc -n lab-rust
sudo k3s kubectl logs -n lab-rust deploy/rust-api
```

## Troubleshooting k3s On e2-micro

If Helm fails with a TLS handshake timeout or `sudo k3s kubectl get nodes` hangs, the VM is usually overloaded rather than unreachable. Check:

```bash
top
free -h
df -h
sudo systemctl status k3s --no-pager
sudo journalctl -u k3s -n 100 --no-pager
sudo ss -ltnp | grep 6443
```

If port `6443` is listening but Kubernetes commands are slow, wait a minute and try again. For fewer false starts, switch `machine_type` to `e2-small` and run:

```bash
terraform -chdir=infra/terraform apply -var-file=terraform.tfvars
./scripts/deploy.sh
```

## Cleanup

```bash
./scripts/destroy.sh
```

This destroys the VM and network resources created by Terraform.
