resource "juju_integration" "server_db" {
  model_uuid  = juju_model.temporal.uuid

  application {
    name      = juju_application.server.name
    endpoint  = "db"
  }

  application {
    offer_url = var.db_interface_offer_url
  }
}

resource "juju_integration" "server_db_visibility" {
  model_uuid  = juju_model.temporal.uuid

  application {
    name      = juju_application.server.name
    endpoint  = "visibility"
  }

  application {
    offer_url = var.db_interface_offer_url
  }
}

resource "juju_integration" "server_admin" {
  model_uuid  = juju_model.temporal.uuid

  application {
    name      = juju_application.server.name
    endpoint  = var.temporal_admin_interface
  }

  application {
    name      = juju_application.admin.name
    endpoint  = var.temporal_admin_interface
  }
}

resource "juju_integration" "server_admin_host" {
  model_uuid  = juju_model.temporal.uuid

  application {
    name      = juju_application.server.name
    endpoint  = var.temporal_host_info_interface
  }

  application {
    name      = juju_application.admin.name
    endpoint  = var.temporal_host_info_interface
  }
}

resource "juju_integration" "server_web_ui" {
  model_uuid  = juju_model.temporal.uuid

  application {
    name      = juju_application.server.name
    endpoint  = var.temporal_ui_interface
  }

  application {
    name      = juju_application.web_ui.name
    endpoint  = var.temporal_ui_interface
  }
}

resource "juju_integration" "server_web_ui_host" {
  model_uuid  = juju_model.temporal.uuid

  application {
    name      = juju_application.server.name
    endpoint  = var.temporal_host_info_interface
  }

  application {
    name      = juju_application.web_ui.name
    endpoint  = var.temporal_host_info_interface
  }
}

resource "juju_offer" "temporal_server" {
  model_uuid       = juju_model.temporal.uuid
  application_name = juju_application.server.name
  endpoints        = [var.temporal_host_info_interface]
}
