data "juju_charm" "grafana_info" {
  charm   = "grafana-k8s"
  channel = "12.4/stable"
  base    = var.ubuntu_base["v26"]
}

data "juju_charm" "loki_info" {
  charm   = "loki-k8s"
  channel = "3.7/stable"
  base    = var.ubuntu_base["v26"]
}

data "juju_charm" "prometheus_info" {
  charm   = "prometheus-k8s"
  channel = "3.11/stable"
  base    = var.ubuntu_base["v26"]
}

data "juju_charm" "ssc_info" {
  charm   = "self-signed-certificates"
  channel = "1/stable"
  base    = var.ubuntu_base["v24"]
}

data "juju_charm" "traefik_info" {
  charm   = "traefik-k8s"
  channel = "latest/stable"
  base    = var.ubuntu_base["v26"]
}