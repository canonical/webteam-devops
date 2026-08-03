variable "model_name" {
  description = "Name of the Juju model that hosts the demo applications."
  type        = string
  default     = "demos"
}

variable "cloud_name" {
  description = "Juju cloud to deploy into."
  type        = string
  default     = "localhost"
}

variable "cloud_region" {
  description = "Cloud region."
  type        = string
  default     = "localhost"
}

variable "app_units" {
  description = "Number of units per app deployed."
  type        = number
  default     = 1
}

# --- Optional ingress coupling -------------------------------------------

variable "haproxy_offer_url" {
  description = <<-EOT
    Cross-model offer URL for the haproxy-route endpoint (output of the
    ingress module). Leave null to deploy the demos standalone, with no
    ingress relation. Example: "jaas-demo:admin/ingress-ps7.haproxy".
  EOT
  type        = string
  default     = null
}
