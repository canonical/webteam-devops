output "db_offer_url" {
  description = "The haproxy:haproxy-route offer to consume"
  value       = juju_offer.db_interface.url
}
