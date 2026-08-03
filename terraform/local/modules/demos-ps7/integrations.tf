# Consume the haproxy-route (HTTP) offer from the ingress model so HAProxy
# terminates TLS with its wildcard cert and routes HTTP traffic to the 
# passthrough ingress -> gateway.
resource "juju_integration" "ingress_haproxy" {
  model_uuid = juju_model.demos.uuid

  application {
    name     = juju_application.passthrough_ingress.name
    endpoint = "haproxy-route"
  }

  application {
    offer_url = module.ingress_ps7.haproxy_route_offer_url
  }
}
