# GCP Network Lab

This is a small Terraform lab for practicing Linux and network debugging on Google Cloud. It creates a custom VPC, two private subnets, two Debian VMs with no public IP addresses, firewall rules for internal traffic, and SSH access through Identity-Aware Proxy (IAP) TCP forwarding.

The lab is intentionally minimal and cost-conscious. It does not create Cloud NAT, load balancers, Filestore, GKE, databases, GPUs, static IPs, or external VM IPs.

## Architecture

- `lab-vpc`: custom VPC with automatic subnet creation disabled.
- `lab-subnet-a`: `10.10.1.0/24` in `us-east1`.
- `lab-subnet-b`: `10.10.2.0/24` in `us-east1`.
- `lab-vm-a`: Debian 12 `e2-micro` VM in `lab-subnet-a`.
- `lab-vm-b`: Debian 12 `e2-micro` VM in `lab-subnet-b`.
- `lab-allow-internal`: allows ICMP, TCP, and UDP from `10.10.0.0/16`.
- `lab-allow-iap-ssh`: allows TCP port 22 from Google IAP's TCP forwarding range, `35.235.240.0/20`, to instances tagged `iap-ssh`.

The VMs install these useful debugging tools at startup:

- `curl`
- `dnsutils`
- `iproute2`
- `iputils-ping`
- `tcpdump`
- `traceroute`
- `lsof`
- `netcat-openbsd`
- `strace`
- `python3`

## GCP VPC And Subnet Scope

A GCP VPC is a global resource. It acts as the network container and can span regions. Subnets are regional resources inside that VPC, so each subnet lives in one region and provides IP ranges for resources in zones within that region.

This is different from cloud platforms where a virtual network is regional. In GCP, one VPC can contain subnets in many regions, which is useful for multi-region private networking without creating separate VPCs for each region.

## Private VMs

The VMs have only private IP addresses. Their Terraform `network_interface` blocks do not include an `access_config`, which means GCP does not assign external IPs.

This keeps the lab closer to real private infrastructure and reduces accidental exposure. The instances can communicate with each other over private RFC 1918 addresses, and you connect to them through IAP SSH instead of public SSH.

Because this lab does not create Cloud NAT, the VMs do not have general outbound internet access after provisioning. Package installation happens during the startup script and may require Private Google Access or NAT in stricter environments. If the startup package install fails, you can still use the lab for routing and firewall practice, or temporarily add controlled egress outside this minimal setup.

## IAP SSH

IAP TCP forwarding lets your local `gcloud` command create a tunnel from your machine to a private VM through Google's IAP service. The VM does not need a public IP address.

At a high level:

1. You authenticate locally with Google Cloud.
2. `gcloud compute ssh --tunnel-through-iap` asks IAP to open a TCP tunnel.
3. The firewall allows SSH from Google's IAP TCP forwarding range.
4. SSH reaches the VM on its private interface.

You still need IAM permissions for IAP TCP forwarding and Compute Engine SSH access in your project.

## Local Authentication

Authenticate and select your project:

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project PROJECT_ID
```

Replace `PROJECT_ID` with your billing-enabled GCP project ID.

## Run Terraform

Create your local variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set:

```hcl
project_id = "your-gcp-project-id"
```

Initialize and apply:

```bash
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## SSH

Use IAP TCP forwarding:

```bash
gcloud compute ssh lab-vm-a --zone us-east1-b --tunnel-through-iap
gcloud compute ssh lab-vm-b --zone us-east1-b --tunnel-through-iap
```

Terraform also outputs the exact commands for your selected zone.

## Basic Debugging Exercises

Get the VM internal IPs from Terraform:

```bash
terraform output vm_internal_ips
```

From `lab-vm-a`, ping `lab-vm-b` by internal IP:

```bash
ping VM_B_INTERNAL_IP
```

On `lab-vm-b`, start a simple HTTP server:

```bash
python3 -m http.server 8080
```

From `lab-vm-a`, curl the server:

```bash
curl http://VM_B_INTERNAL_IP:8080
```

Check listening sockets on `lab-vm-b`:

```bash
ss -ltnp
```

Inspect routing on either VM:

```bash
ip route
```

Observe ICMP or TCP traffic with `tcpdump`:

```bash
sudo tcpdump -ni any icmp
sudo tcpdump -ni any tcp port 8080
```

## Failure Exercises

Temporarily remove or comment out the `lab-allow-internal` firewall rule in `firewall.tf`, then run:

```bash
terraform apply -var-file=terraform.tfvars
```

Try the ping and curl tests again. You should see failures because the VPC firewall no longer allows that internal traffic.

On `lab-vm-b`, bind the Python server to localhost only:

```bash
python3 -m http.server 8080 --bind 127.0.0.1
```

From `lab-vm-a`, curl `VM_B_INTERNAL_IP:8080` again. It should fail because the service is listening only on `lab-vm-b`'s loopback interface, not on its private network interface.

Compare DNS and host lookup tools:

```bash
dig example.com
getent hosts example.com
cat /etc/hosts
```

Then add a temporary test entry to `/etc/hosts` and compare the behavior again:

```bash
echo "10.10.2.10 fake-lab-host" | sudo tee -a /etc/hosts
getent hosts fake-lab-host
dig fake-lab-host
```

`getent hosts` uses the system name service configuration, including `/etc/hosts`. `dig` queries DNS directly and does not use `/etc/hosts`.

## Cleanup

Destroy all lab resources:

```bash
terraform destroy -var-file=terraform.tfvars
```
