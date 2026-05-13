resource "google_compute_firewall" "internal" {
  name    = "${local.name_prefix}-allow-internal"
  network = google_compute_network.lab.name

  description   = "Allow private lab traffic between subnets for network debugging practice."
  source_ranges = ["10.10.0.0/16"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
}

resource "google_compute_firewall" "iap_ssh" {
  name    = "${local.name_prefix}-allow-iap-ssh"
  network = google_compute_network.lab.name

  description   = "Allow SSH only through Google IAP TCP forwarding."
  source_ranges = var.ssh_source_ranges
  target_tags   = ["iap-ssh"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
