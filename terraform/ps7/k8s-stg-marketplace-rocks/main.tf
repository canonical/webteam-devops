locals {
  juju_model_owner = "795798e4-922f-49c7-9169-004ffc17df90@serviceaccount"
  juju_model_name  = "k8s-stg-marketplace-default"
}

data "juju_model" "service_model" {
  owner = local.juju_model_owner
  name  = local.juju_model_name
}

data "juju_charm" "rocks_storefront_charm" {
  charm   = var.charm_name
  channel = "latest/beta"
  base    = "ubuntu@24.04"
}

resource "juju_application" "rocks_storefront" {
  model_uuid = data.juju_model.service_model.uuid
  units      = 2

  charm {
    name     = var.charm_name
    channel  = var.charm_channel
    revision = data.juju_charm.rocks_storefront_charm.revision
  }

  resources = data.juju_charm.rocks_storefront_charm.resources

  expose {
    cidrs = "10.0.0.0/8"
  }

  config = {
    "juju-external-hostname" = var.hostname
  }
}

resource "juju_application" "ingress_configurator" {
  model_uuid  = data.juju_model.service_model.uuid
  units       = 1

  charm {
    name      = "ingress-configurator"
    channel   = "latest/stable"
  }

  trust = true

  config = {
    hostname  = var.hostname
  }
}

resource "juju_integration" "ingress_app" {
  model_uuid  = data.juju_model.service_model.uuid

  application {
    name      = juju_application.rocks_storefront.name
    endpoint  = var.ingress_endpoint
  }

  application {
    name      = juju_application.ingress_configurator.name
    endpoint  = var.ingress_endpoint
  }
}

resource "juju_integration" "ingress_haproxy" {
  model_uuid  = data.juju_model.service_model.uuid

  application {
    name      = juju_application.ingress_configurator.name
    endpoint  = "haproxy-route"
  }

  application {
    offer_url = "795798e4-922f-49c7-9169-004ffc17df90@serviceaccount/prod-cloud-ingress-ps7.ingress-ps7-webdesign"
  }
}
