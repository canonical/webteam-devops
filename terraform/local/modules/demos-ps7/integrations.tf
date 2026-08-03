# HAProxy terminates TLS with its wildcard cert and routes HTTP traffic to the
# passthrough ingress -> gateway. The passthrough ingress-configurator runs in
# the same (machine) model as HAProxy, so this is a local relation rather than a
# cross-model consumption of the haproxy-route offer. The offer is still exported
# by the ingress module for other environments/apps that consume it cross-model.
resource "juju_integration" "ingress_haproxy" {
  model_uuid = module.ingress_ps7.machine_model_uuid

  application {
    name     = juju_application.passthrough_ingress.name
    endpoint = "haproxy-route"
  }

  application {
    name     = module.ingress_ps7.haproxy_app_name
    endpoint = "haproxy-route"
  }
}
