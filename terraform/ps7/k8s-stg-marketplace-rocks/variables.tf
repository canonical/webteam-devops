variable "approle_role_id" {
  description = "Approle Role ID"
  type        = string
  default     = null
}

variable "approle_secret_id" {
  description = "Approle Secret ID"
  type        = string
  default     = null
  sensitive   = true
}

variable "hostname" {
  description = "Hostname the ingress-configurator advertises to HAProxy for this app."
  type        = string
  default     = "staging.rocks.ubuntu.com"
}

variable "ingress_endpoint" {
  description = "ingress relation endpoint"
  type        = string
  default     = "ingress"
}

variable "charm_name" {
  description = "Name of the charmed application."
  type        = string
  default     = "rocks-storefront"
}

variable "charm_channel" {
  description = "Name of the channel for the charmed application."
  type        = string
  default     = "latest/beta"
}
