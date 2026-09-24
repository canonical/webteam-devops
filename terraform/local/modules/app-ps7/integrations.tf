resource "juju_integration" "ingress_haproxy" {
  model_uuid  = juju_model.app.uuid

  application {
    name      = juju_application.ingress_configurator.name
    endpoint  = "haproxy-route"
  }

  application {
    offer_url = var.haproxy_route_offer_url
  }
}
