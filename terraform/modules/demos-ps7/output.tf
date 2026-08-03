output "model_name" {
  description = "Name of the demos model."
  value       = juju_model.demos.name
}

output "model_uuid" {
  description = "UUID of the demos model."
  value       = juju_model.demos.uuid
}
