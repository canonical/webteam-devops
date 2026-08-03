variable "model_name" {
  description = "Name of the Juju model that hosts the charms for the application."
  type        = string
  default     = "app"
}

variable "units" {
  description = "Number of units for an application."
  type        = number
  default     = 1
}

variable "hostname" {
  description = "Hostname the ingress-configurator advertises to HAProxy for this app."
  type        = string
  default     = "app.local"
}
