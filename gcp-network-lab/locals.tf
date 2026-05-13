locals {
  name_prefix = "lab"

  common_labels = {
    environment = "lab"
    purpose     = "network-debugging"
    owner       = "personal"
  }
}
