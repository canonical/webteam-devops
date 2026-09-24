variable "model_name" {
  description = "Name of the Juju model that hosts the charms for the application."
  type        = string
  default     = "temporal"
}

variable "units" {
  description = "Number of units per application."
  type        = map(number)
  default     = {
    temporal-k8s    = 1
    db              = 1
    temporal-admin  = 1
    web-ui          = 1
    ingress         = 1
  }
}

variable "hostname" {
  description = "Hostname the ingress-configurator advertises to HAProxy for Temporal UI."
  type        = string
  default     = "temporal.local"
}

variable "haproxy_route_offer_url" {
  description = "The haproxy:haproxy-route offer to consume"
  type        = string
}