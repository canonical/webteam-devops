variable "machine_model_name" {
  description = "Name of the Juju model that hosts the HAProxy machine charm."
  type        = string
  default     = "ingress-ps7-machine"
}

variable "app_name" {
  description = "Name of the HAProxy Juju application to forward traffic to."
  type        = string
  default     = "haproxy"
}

variable "ports" {
  description = "Comma-separated list of TCP ports to forward from the VM to HAProxy."
  type        = string
  default     = "80,443"
}

variable "hostnames" {
  description = "Hostnames served by the ingress, to be resolved to the VM on the host."
  type        = list(string)
}

variable "certificates_model_name" {
  description = "Name of the Juju (K8s) model that hosts the self-signed-certificates charm."
  type        = string
  default     = "ingress-ps7-k8s"
}

variable "certificates_app_name" {
  description = "Name of the self-signed-certificates Juju application."
  type        = string
  default     = "self-signed-certificates"
}
