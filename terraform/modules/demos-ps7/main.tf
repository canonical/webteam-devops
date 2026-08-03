terraform {
  required_providers {
    juju = {
      source  = "juju/juju"
      version = "~> 1.1.0"
    }
  }
}

resource "juju_model" "demos" {
  name = var.model_name

  cloud {
    name   = var.cloud_name
    region = var.cloud_region
  }
}

# Gateway API to route to each demo app
resource "juju_application" "gateway-api" {
  name        = "gateway-api"
  model_uuid  = juju_model.demos.uuid
  units       = var.app_units

  charm {
    name      = "gateway-api-integrator"
  }

  config = {
    gateway-class     = "traefik"
  }
}

resource "juju_application" "passthrough_ingress" {
  model_uuid  = juju_model.demos.uuid
  units       = var.app_units

  charm {
    name      = "ingress-configurator"
  }

  config = {
    # TODO
  }
}

