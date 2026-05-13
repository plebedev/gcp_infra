resource "google_compute_network" "lab" {
  name                    = "${local.name_prefix}-vpc"
  auto_create_subnetworks = false

  # GCP VPC networks are global containers. Subnets are regional resources
  # inside that VPC, which lets one VPC span multiple regions intentionally.
}

resource "google_compute_subnetwork" "subnet_a" {
  name          = "${local.name_prefix}-subnet-a"
  ip_cidr_range = "10.10.1.0/24"
  region        = var.region
  network       = google_compute_network.lab.id
}

resource "google_compute_subnetwork" "subnet_b" {
  name          = "${local.name_prefix}-subnet-b"
  ip_cidr_range = "10.10.2.0/24"
  region        = var.region
  network       = google_compute_network.lab.id
}
