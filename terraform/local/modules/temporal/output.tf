output "model_name" {
  description = "Name of the temporal model."
  value       = juju_model.temporal.name
}

output "model_uuid" {
  description = "UUID of the temporal model."
  value       = juju_model.temporal.uuid
}

output "ingress_app_name" {
  description = "The ingress_configurator:ingress temporal to integrate."
  value       = juju_application.ingress_configurator.name
}

output "ingress_hostname" {
  description = "Hostname the ingress-configurator advertises for Temporal UI."
  value       = var.hostname
}
