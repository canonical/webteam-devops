terraform {
  required_providers {
    juju = {
      source  = "juju/juju"
      version = "~> 1.1.0"
    }
  }
}

provider "juju" {}

module "demos_ps7" {
  source = "../modules/demos-ps7"

  hostname             = var.hostname
  gateway_backend_port = var.gateway_backend_port
}

# Discovers the VM external IP and the HAProxy unit IP, and exposes them (plus
# the ingress hostnames) as outputs. Depends on demos_ps7 so discovery runs
# only after the ingress/HAProxy stack exists.
# There should be a script in webteam-juju-dev-provisioning called
# configure_ingress_forwarding.sh that consumes these to configure host access.
module "host_access" {
  source = "../modules/host-access"

  machine_model_name = module.demos_ps7.machine_model_name
  app_name           = module.demos_ps7.haproxy_app_name
  hostnames          = [module.demos_ps7.hostname]

  certificates_model_name = module.demos_ps7.k8s_model_name
  certificates_app_name   = module.demos_ps7.certificates_app_name

  depends_on = [module.demos_ps7]
}

resource "juju_application" "pr" {
  for_each   = var.pr_apps
  name       = each.key
  model_uuid = module.demos_ps7.model_uuid
  units      = each.value.units

  charm {
    name    = each.value.charm
    channel = "latest/stable"
  }
}

# One ingress-configurator per PR, each with its own hostname. Each registers
# its own HTTPRoute on the shared gateway-api Gateway via the gateway-route
# relation (see "route multiple workloads through a single Gateway").
resource "juju_application" "pr_ingress" {
  for_each    = var.pr_apps
  name        = "${each.key}-ingress"
  model_uuid  = module.demos_ps7.model_uuid
  units       = 1

  charm {
    name      = "ingress-configurator"
    channel   = "latest/stable"
  }

  trust = true

  config = {
    hostname  = each.value.hostname
  }
}

resource "juju_integration" "pr_gateway_route" {
  for_each   = var.pr_apps
  model_uuid = module.demos_ps7.model_uuid

  application {
    name     = juju_application.pr_ingress[each.key].name
    endpoint = "gateway-route"
  }

  application {
    name     = module.demos_ps7.gateway_app_name
    endpoint = "gateway-route"
  }
}

resource "juju_integration" "pr_ingress_backend" {
  for_each   = var.pr_apps
  model_uuid = module.demos_ps7.model_uuid

  application {
    name     = juju_application.pr[each.key].name
    endpoint = "ingress"
  }

  application {
    name     = juju_application.pr_ingress[each.key].name
    endpoint = "ingress"
  }
}
