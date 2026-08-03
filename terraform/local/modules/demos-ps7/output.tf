output "model_name" {
  description = "Name of the demos model."
  value       = juju_model.demos.name
}

output "model_uuid" {
  description = "UUID of the demos model."
  value       = juju_model.demos.uuid
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

output "gateway_app_name" {
  description = "Name of the gateway-api-integrator application."
  value       = juju_application.gateway-api.name
}

output "gateway_ip" {
  description = <<-EOT
    Discovered external IP of the gateway-api gateway (backend that HAProxy routes to).
    Empty until the gateway has settled.
  EOT
  value       = data.external.gateway_ip.result.ip
}

output "hostname" {
  description = "Hostname HAProxy matches on / requests a certificate for."
  value       = var.hostname
}
