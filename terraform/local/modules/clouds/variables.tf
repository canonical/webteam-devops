variable "machines_cloud_name" {
  description = "Juju cloud to deploy machine charms into."
  type        = string
  default     = "localhost"
}

variable "k8s_cloud_name" {
  description = "Juju cloud to deploy k8s charms into."
  type        = string
  default     = "mk8s"
}

variable "cloud_region" {
  description = "Cloud region."
  type        = string
  default     = "localhost"
}
