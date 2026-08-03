variable "ingress_machine_model_name" {
  description = "Name of the Juju model that hosts the machine charms used for ingress."
  type        = string
  default     = "ingress-ps7-machine"
}

variable "ingress_k8s_model_name" {
  description = "Name of the Juju model that hosts the k8s charms used for ingress."
  type        = string
  default     = "ingress-ps7-k8s"
}

variable "units" {
  description = "Number of units for an application."
  type        = number
  default     = 1
}
