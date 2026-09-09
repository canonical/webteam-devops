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
