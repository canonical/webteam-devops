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

output "machine_model_name" {
  description = "Name of the Juju model that hosts the HAProxy machine charm."
  value       = module.ingress_ps7.ingress_machine_model_name
}

output "k8s_model_name" {
  description = "Name of the Juju model that hosts the self-signed-certificates charm."
  value       = module.ingress_ps7.ingress_k8s_model_name
}

output "haproxy_app_name" {
  description = "Name of the HAProxy Juju application."
  value       = module.ingress_ps7.haproxy_app_name
}

output "certificates_app_name" {
  description = "Name of the self-signed-certificates Juju application."
  value       = module.ingress_ps7.certificates_app_name
}
