terraform {
  required_providers {
    juju = {
      source  = "juju/juju"
      version = "~> 1.1.0"
    }
  }
}

module "clouds" {
  source = "../clouds"
}

module "ingress_ps7" {
  source = "../ingress-ps7"
}

resource "juju_model" "app" {
  name = var.model_name

  cloud {
    name    = module.clouds.k8s_cloud_name
    region  = module.clouds.cloud_region
  }

  credential = "mk8s"
}

resource "juju_application" "ingress_configurator" {
  model_uuid  = juju_model.app.uuid
  units       = var.units

  charm {
    name      = "ingress-configurator"
    channel   = "latest/stable"
  }

  trust = true

  config = {
    hostname  = var.hostname
  }
}
