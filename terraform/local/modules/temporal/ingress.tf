resource "juju_application" "ingress_configurator" {
  model_uuid  = juju_model.temporal.uuid
  units       = var.units["ingress"]

  charm {
    name      = "ingress-configurator"
    channel   = "latest/stable"
  }

  trust = true

  config = {
    hostname  = var.hostname
  }
}

resource "juju_integration" "ingress_web_ui" {
  model_uuid  = juju_model.temporal.uuid

  application {
    name      = juju_application.web_ui.name
    endpoint  = "ingress"
  }

  application {
    name      = juju_application.ingress_configurator.name
    endpoint  = "ingress"
  }
}

resource "juju_integration" "ingress_haproxy" {
  model_uuid  = juju_model.temporal.uuid

  application {
    name      = juju_application.ingress_configurator.name
    endpoint  = "haproxy-route"
  }

  application {
    offer_url = var.haproxy_route_offer_url
  }
}
