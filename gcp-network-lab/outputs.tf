output "vpc_name" {
  description = "Name of the custom VPC."
  value       = google_compute_network.lab.name
}

output "subnets" {
  description = "Subnet names and CIDR ranges."
  value = {
    subnet_a = {
      name = google_compute_subnetwork.subnet_a.name
      cidr = google_compute_subnetwork.subnet_a.ip_cidr_range
    }
    subnet_b = {
      name = google_compute_subnetwork.subnet_b.name
      cidr = google_compute_subnetwork.subnet_b.ip_cidr_range
    }
  }
}

output "vm_names" {
  description = "Names of the lab VMs."
  value = [
    google_compute_instance.vm_a.name,
    google_compute_instance.vm_b.name,
  ]
}

output "vm_internal_ips" {
  description = "Internal IP addresses for the lab VMs."
  value = {
    vm_a = google_compute_instance.vm_a.network_interface[0].network_ip
    vm_b = google_compute_instance.vm_b.network_interface[0].network_ip
  }
}

output "iap_ssh_commands" {
  description = "Exact gcloud commands for SSH through IAP TCP forwarding."
  value = {
    vm_a = "gcloud compute ssh ${google_compute_instance.vm_a.name} --zone ${var.zone} --tunnel-through-iap"
    vm_b = "gcloud compute ssh ${google_compute_instance.vm_b.name} --zone ${var.zone} --tunnel-through-iap"
  }
}
