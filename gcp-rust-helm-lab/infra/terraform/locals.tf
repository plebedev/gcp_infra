locals {
  name_prefix = "lab-rust"

  common_labels = {
    environment = "lab"
    purpose     = "rust-helm-e2e"
    owner       = "personal"
  }

  network_tag = "${local.name_prefix}-web"
}
