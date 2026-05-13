output "vm_name" {
  description = "Name of the lab VM."
  value       = google_compute_instance.main.name
}

output "vm_zone" {
  description = "Zone of the lab VM."
  value       = var.zone
}

output "vm_public_ip" {
  description = "Ephemeral public IP address assigned to the VM."
  value       = google_compute_instance.main.network_interface[0].access_config[0].nat_ip
}

output "ssh_command" {
  description = "Command to SSH to the VM through IAP."
  value       = "gcloud compute ssh ${google_compute_instance.main.name} --zone ${var.zone} --tunnel-through-iap"
}

output "service_url" {
  description = "Public base URL for the Helm-deployed Rust API."
  value       = "http://${google_compute_instance.main.network_interface[0].access_config[0].nat_ip}"
}
