variable "model_name" {
  description = "Name of the Juju model that hosts the charms for Temporal."
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

variable "db_interface_offer_url" {
  description = "The postgresql offer with interface 'database' to consume"
  type        = string
}

variable "database_interface" {
  description = "Name of the database interface/endpoint."
  type        = string
  default     = "database"
}

variable "temporal_host_info_interface" {
  description = "Name of the temporal-host-info interface/endpoint."
  type        = string
  default     = "temporal-host-info"
}

variable "temporal_ui_interface" {
  description = "Name of Temporal's ui interface/endpoint."
  type        = string
  default     = "ui"
}

variable "temporal_admin_interface" {
  description = "Name of Temporal's admin interface/endpoint."
  type        = string
  default     = "admin"
}
