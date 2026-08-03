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
resource "juju_application" "passthrough_ingress" {
  model_uuid  = juju_model.demos.uuid
  units       = var.app_units

  charm {
    name      = "ingress-configurator"
  }

  trust = true

  config = {
    allow-http        = true
    backend-addresses = data.external.gateway_ip.result.ip
    backend-ports     = tostring(var.gateway_backend_port)
    hostname          = var.hostname
  }
}

