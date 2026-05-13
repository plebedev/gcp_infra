resource "google_compute_firewall" "ssh" {
  name    = "${local.name_prefix}-allow-iap-ssh"
  network = google_compute_network.main.name

  description   = "Allow SSH through Google IAP TCP forwarding only."
  source_ranges = var.iap_ssh_source_ranges
  target_tags   = [local.network_tag]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "web" {
  name    = "${local.name_prefix}-allow-web"
  network = google_compute_network.main.name

  description   = "Allow public HTTP and HTTPS traffic to the Helm-deployed service."
  source_ranges = var.web_source_ranges
  target_tags   = [local.network_tag]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}
