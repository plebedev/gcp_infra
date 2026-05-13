data "google_compute_image" "debian_12" {
  family  = "debian-12"
  project = "debian-cloud"
}

locals {
  startup_script = <<-EOT
    #!/usr/bin/env bash
    set -euxo pipefail

    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends \
      curl \
      dnsutils \
      iproute2 \
      iputils-ping \
      lsof \
      netcat-openbsd \
      python3 \
      strace \
      tcpdump \
      traceroute
  EOT
}

resource "google_compute_instance" "vm_a" {
  name         = "${local.name_prefix}-vm-a"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["iap-ssh"]
  labels       = local.common_labels

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian_12.self_link
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_a.id

    # No access_config block means no external IP. SSH access uses IAP instead.
  }

  metadata_startup_script = local.startup_script

  allow_stopping_for_update = true
}

resource "google_compute_instance" "vm_b" {
  name         = "${local.name_prefix}-vm-b"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["iap-ssh"]
  labels       = local.common_labels

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian_12.self_link
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_b.id

    # No access_config block means no external IP. SSH access uses IAP instead.
  }

  metadata_startup_script = local.startup_script

  allow_stopping_for_update = true
}
