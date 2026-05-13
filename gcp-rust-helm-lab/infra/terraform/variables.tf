variable "project_id" {
  description = "Billing-enabled GCP project ID where the lab resources will be created."
  type        = string
}

variable "region" {
  description = "GCP region for the subnet."
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "GCP zone for the VM."
  type        = string
  default     = "us-east1-b"
}

variable "machine_type" {
  description = "Machine type for the single-node lab VM."
  type        = string
  default     = "e2-micro"
}

variable "iap_ssh_source_ranges" {
  description = "CIDR ranges allowed to SSH to the VM. Defaults to Google IAP TCP forwarding only."
  type        = list(string)
  default     = ["35.235.240.0/20"]
}

variable "web_source_ranges" {
  description = "CIDR ranges allowed to reach the public web endpoint on HTTP and HTTPS."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "boot_disk_size_gb" {
  description = "Boot disk size for the VM."
  type        = number
  default     = 20
}
