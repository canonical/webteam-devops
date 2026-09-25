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

resource "juju_model" "temporal" {
  name = var.model_name

  cloud {
    name    = module.clouds.k8s_cloud_name
    region  = module.clouds.cloud_region
  }

  credential = "mk8s"
}

resource "juju_application" "server" {
  model_uuid  = juju_model.temporal.uuid
  units       = var.units["temporal-k8s"]

  charm {
    name      = "temporal-k8s"
    channel   = "1.23/stable"
    base      = "ubuntu@24.04"
  }

  config = {
    num-history-shards  = 4
  }
}

resource "juju_application" "db" {
  model_uuid  = juju_model.temporal.uuid
  units       = var.units["db"]

  charm {
    name      = "postgresql-k8s"
    channel   = "14/stable"
  }

  trust = true
}

resource "juju_application" "admin" {
  model_uuid  = juju_model.temporal.uuid
  units       = var.units["temporal-admin"]

  charm {
    name      = "temporal-admin-k8s"
    channel   = "1.23/stable"
    base      = "ubuntu@24.04"
  }
}

# Execute action to create a default namespace in Temporal.
# The script waits for the applications and relations to have settled
# before running the action so that `terraform apply` doesn't fail.
data "external" "create_namespace" {
  program = ["python3", "${path.module}/scripts/create_namespace.py"]

  query = {
    model = juju_model.temporal.name
    app   = juju_application.admin.name
  }
}

resource "juju_application" "web_ui" {
  model_uuid  = juju_model.temporal.uuid
  units       = var.units["web-ui"]

  charm {
    name      = "temporal-ui-k8s"
    channel   = "1.23/stable"
    base      = "ubuntu@24.04"
  }
}
