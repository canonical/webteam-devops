variable "hostname" {
  description = "Wildcard hostname HAProxy matches on and requests a cert for (e.g. \"*.demos.local\")."
  type        = string
  default     = "*.demos.local"
}

variable "gateway_backend_port" {
  description = "Port the gateway (traefik) listens on for plain HTTP traffic."
  type        = number
  default     = 80
}

variable "pr_apps" {
  description = "Demo PR apps routed through the shared gateway. Key = ingress-configurator app name."
  type = map(object({
    units    = optional(number, 1)
    hostname = string
    charm    = string
  }))
  default = {
    pr1 = { units = 1, hostname = "pr1.demos.local", charm = "charmhub-io" }
    pr2 = { units = 2, hostname = "pr2.demos.local", charm = "rockstore-io" }
  }
}
