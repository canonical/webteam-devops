resource "juju_offer" "db_interface" {
  model_uuid       = juju_model.db.uuid
  application_name = juju_application.postgres.name
  endpoints        = ["database", "db"]
}
