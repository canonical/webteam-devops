variable "model_name" {
  description = "Name of the Juju model that hosts the charms for the databases."
  type        = string
  default     = "db"
}

variable "units" {
  description = "Number of units for an application."
  type        = number
  default     = 1
}
