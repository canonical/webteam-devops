terraform {
  required_providers {
    juju = {
      source  = "juju/juju"
      version = "~> 1.1.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.3.0"
    }
  }
}

module "clouds" {
  source = "../clouds"
}

module "ingress_ps7" {
  source = "../ingress-ps7"
}

resource "juju_model" "demos" {
  name = var.model_name

  cloud {
    name   = module.clouds.k8s_cloud_name
    region = module.clouds.cloud_region
  }

  credential = "mk8s"
}

# Gateway API to route to each demo app
resource "juju_application" "gateway-api" {
  name        = "gateway-api"
  model_uuid  = juju_model.demos.uuid
  units       = var.app_units

  charm {
    name      = "gateway-api-integrator"
    channel   = "1/stable"
  }

  trust = true

  config = {
    enforce-https     = false
    gateway-class     = "traefik"
  }
}

# Discover the gateway's IP address. The gateway address is only assigned once the
# gateway-api-integrator charm has settled, and the juju/juju provider does
# not surface it, so we read it via an external data source.
# depends_on defers this to apply-time (after the app is deployed), and
# the script polls until the address is ready so the first apply succeeds.
data "external" "gateway_ip" {
  program = ["python3", "${path.module}/scripts/gateway_addr.py"]

  query = {
    model = juju_model.demos.name
    app   = juju_application.gateway-api.name
  }

  depends_on = [juju_application.gateway-api]
}

# Passthrough ingress: HAProxy terminates TLS (via its certificates relation)
# and routes HTTP to the gateway, which performs host-based routing to each
# demo app.
#
# This runs on the machine substrate (alongside HAProxy) rather than on
# Kubernetes. The ingress-configurator's "integrator mode" (backend-addresses /
# backend-ports config) is only supported on machine substrates; on Kubernetes
# the charm requires an `ingress` relation from a workload app and blocks with
# "Ingress relation required on Kubernetes substrate.". The gateway is not an
# ingress requirer, so we deploy the passthrough as a machine charm and feed it
# the gateway IP via config.
resource "juju_application" "passthrough_ingress" {
  model_uuid  = module.ingress_ps7.machine_model_uuid
  units       = var.app_units

  charm {
    name      = "ingress-configurator"
  }

  config = {
    allow-http        = true
    backend-addresses = data.external.gateway_ip.result.ip
    backend-ports     = tostring(var.gateway_backend_port)
    hostname          = var.hostname
  }
}

