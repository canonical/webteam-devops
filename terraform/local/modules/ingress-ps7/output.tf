output "ingress_k8s_model_name" {
  description = "Name of the k8s ingress model."
  value       = juju_model.ingress_k8s.name
}

output "ingress_k8s_model_uuid" {
  description = "UUID of the k8s ingress model."
  value       = juju_model.ingress_k8s.uuid
}

output "ingress_machine_model_name" {
  description = "Name of the machines ingress model."
  value       = juju_model.ingress_machines.name
}

output "machine_model_uuid" {
  description = "UUID of the machines ingress model."
  value       = juju_model.ingress_machines.uuid
}

output "haproxy_route_offer_url" {
  description = "The haproxy:haproxy-route offer to consume"
  value       = juju_offer.haproxy_route.url
}

output "haproxy_app_name" {
  description = "Name of the HAProxy Juju application."
  value       = juju_application.haproxy.name
}

output "certificates_app_name" {
  description = "Name of the self-signed-certificates Juju application."
  value       = juju_application.certificates.name
}
