variable "model_name" {
  description = "Name of the Juju model that hosts the demo applications."
  type        = string
  default     = "demos"
}

variable "app_units" {
  description = "Number of units per app deployed."
  type        = number
  default     = 1
}

# Ingress / gateway routing

variable "hostname" {
  description = <<-EOT
    Hostname HAProxy matches on and requests a certificate for. Use a wildcard
    (e.g. "*.demos.local") so a single HAProxy cert covers every demo host; the
    gateway will then routes per-host (pr1.demos.local, pr2.demos.local, ...).
  EOT
  type        = string
  default     = "*.demos.local"
}

variable "gateway_backend_port" {
  description = "Port the gateway (traefik) listens on for plain HTTP traffic."
  type        = number
  default     = 80
}
