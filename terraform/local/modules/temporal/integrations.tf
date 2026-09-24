resource "juju_integration" "server_db" {
  model_uuid  = juju_model.temporal.uuid

  application {
    name      = juju_application.server.name
    endpoint  = "db"
  }

  application {
    name      = juju_application.db.name
    endpoint  = "database"
  }
}

resource "juju_integration" "server_db_visibility" {
  model_uuid  = juju_model.temporal.uuid

  application {
    name      = juju_application.server.name
    endpoint  = "visibility"
  }

  application {
    name      = juju_application.db.name
    endpoint  = "database"
  }
}

resource "juju_integration" "server_admin" {
  model_uuid  = juju_model.temporal.uuid

  application {
    name      = juju_application.server.name
    endpoint  = "admin"
  }

  application {
    name      = juju_application.admin.name
    endpoint  = "admin"
  }
}

resource "juju_integration" "server_admin_host" {
  model_uuid  = juju_model.temporal.uuid

  application {
    name      = juju_application.server.name
    endpoint  = "temporal-host-info"
  }

  application {
    name      = juju_application.admin.name
    endpoint  = "temporal-host-info"
  }
}

resource "juju_integration" "server_web_ui" {
  model_uuid  = juju_model.temporal.uuid

  application {
    name      = juju_application.server.name
    endpoint  = "ui"
  }

  application {
    name      = juju_application.web_ui.name
    endpoint  = "ui"
  }
}

resource "juju_integration" "server_web_ui_host" {
  model_uuid  = juju_model.temporal.uuid

  application {
    name      = juju_application.server.name
    endpoint  = "temporal-host-info"
  }

  application {
    name      = juju_application.web_ui.name
    endpoint  = "temporal-host-info"
  }
}
