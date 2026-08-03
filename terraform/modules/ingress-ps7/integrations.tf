resource "juju_integration" "certificates_haproxy" {
  model_uuid  = juju_model.ingress_machines.uuid

  application {
    name      = juju_application.haproxy.name
    endpoint  = "certificates"
  }

  application {
    offer_url = juju_offer.certificates_offer.url
  }
}

resource "juju_offer" "certificates_offer" {
  model_uuid        = juju_model.ingress_k8s.uuid
  application_name  = juju_application.certificates.name
  endpoints         = ["certificates"]
}

# This will be used by the application module to consume haproxy_route,
# the same as in a PS7 environment
resource "juju_offer" "haproxy_route" {
  model_uuid       = juju_model.ingress_machines.uuid
  application_name = juju_application.haproxy.name
  endpoints        = ["haproxy-route"]
}
