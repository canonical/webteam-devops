locals {
  juju_model_owner = "795798e4-922f-49c7-9169-004ffc17df90@serviceaccount"
  juju_model_name  = "k8s-stg-marketplace-default"
}

data "juju_model" "service_model" {
  owner = local.juju_model_owner
  name  = local.juju_model_name
}

data "juju_secret" "test_data_source" {
  name       = "test_secret"
  model_uuid = data.juju_model.service_model.uuid
}
