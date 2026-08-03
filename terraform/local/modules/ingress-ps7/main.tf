terraform {
  required_providers {
    juju = {
      source  = "juju/juju"
      version = "~> 1.1.0"
    }
  }
}

module "clouds" {
  source  = "../clouds"
}

# Models for machine charms and k8s charms
resource "juju_model" "ingress_machines" {
  name = var.ingress_machine_model_name

  cloud {
    name    = module.clouds.machines_cloud_name
    region  = module.clouds.cloud_region
  }
}
resource "juju_model" "ingress_k8s" {
  name = var.ingress_k8s_model_name

  cloud {
    name    = module.clouds.k8s_cloud_name
    region  = module.clouds.cloud_region
  }

  credential = "mk8s"
}

# Machine applications
resource "juju_application" "haproxy" {
  model_uuid = juju_model.ingress_machines.uuid
  units      = var.units

  charm {
    name    = "haproxy"
    channel = "2.8/stable"
  }
}

# K8s applications
resource "juju_application" "certificates" {
  model_uuid  = juju_model.ingress_k8s.uuid
  units       = var.units

  charm {
    name    = "self-signed-certificates"
  }
}

# We use self-signed-certificates because the full LEGO set-up is impossible to
# set up locally, as we don't have a DNS server that we can use to prove domain
# ownership to the LE ACME server.
# For the real architecture used in PS7 for ingress see:
# https://miro.com/app/board/uXjVH4B9jCA=/?moveToWidget=3458764679218439103&cot=14
