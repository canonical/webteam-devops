terraform {
  required_providers {
    juju = {
      source  = "juju/juju"
      version = "~> 2.3"
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

resource "juju_model" "db" {
  name = var.model_name

  cloud {
    name    = module.clouds.k8s_cloud_name
    region  = module.clouds.cloud_region
  }

  credential = "mk8s"
}

resource "juju_application" "postgres" {
  model_uuid  = juju_model.db.uuid
  units       = var.units

  charm {
    name      = "postgresql-k8s"
    channel   = "14/stable"
  }

  trust = true
}
