locals {
  juju_model_owner = "795798e4-922f-49c7-9169-004ffc17df90@serviceaccount"
  juju_model_name  = "k8s-prod-marketplace-default"
}

data "juju_model" "service_model" {
  owner = local.juju_model_owner
  name  = local.juju_model_name
}
