output "model_name" {
  description = "Name of the app model."
  value       = juju_model.app.name
}

output "model_uuid" {
  description = "UUID of the app model."
  value       = juju_model.app.uuid
}

output "ingress_app_name" {
  description = "The ingress_configurator:ingress app to integrate."
  value       = juju_application.ingress_configurator.name
}

output "ingress_hostname" {
  description = "Hostname the ingress-configurator advertises for this app."
  value       = var.hostname
}
