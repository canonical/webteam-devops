output "machines_cloud_name" {
  description = "Juju cloud to deploy machine charms into."
  value       = var.machines_cloud_name
}

output "k8s_cloud_name" {
  description = "Juju cloud to deploy k8s charms into."
  value       = var.k8s_cloud_name
}

output "cloud_region" {
  description = "Cloud region."
  value       = var.cloud_region
}
