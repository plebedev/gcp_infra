data "google_compute_image" "debian_12" {
  family  = "debian-12"
  project = "debian-cloud"
}

locals {
  startup_script = <<-EOT
    #!/usr/bin/env bash
    set -euxo pipefail

    apt-get update
    apt-get install -y --no-install-recommends ca-certificates curl

    if ! command -v k3s >/dev/null 2>&1; then
      curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 644 --disable traefik" sh -
    fi
  EOT
}

resource "google_compute_instance" "main" {
  name         = "${local.name_prefix}-vm"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = [local.network_tag]
  labels       = local.common_labels

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian_12.self_link
      size  = var.boot_disk_size_gb
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.id

    # This lab intentionally uses an ephemeral public IP so the HTTP endpoint is
    # easy to test end to end without provisioning a managed load balancer.
    access_config {}
  }

  metadata_startup_script = local.startup_script

  allow_stopping_for_update = true
}
