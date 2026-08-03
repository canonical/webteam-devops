variable "ubuntu_base" {
  description = "The ubuntu base version for a charm"
  type = map(string)
  default = {
    v24 = "ubuntu@24.04"
    v26 = "ubuntu@26.04"
  }
}
