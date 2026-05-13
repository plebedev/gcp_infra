variable "project_id" {
  description = "Billing-enabled GCP project ID where the lab resources will be created."
  type        = string
}

variable "region" {
  description = "GCP region for regional resources such as subnets."
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "GCP zone for the VM instances."
  type        = string
  default     = "us-east1-b"
}

variable "machine_type" {
  description = "Machine type for the lab VMs."
  type        = string
  default     = "e2-micro"
}

variable "ssh_source_ranges" {
  description = "Source ranges allowed to reach tcp/22 on instances tagged for IAP SSH."
  type        = list(string)
  default     = ["35.235.240.0/20"]
}
