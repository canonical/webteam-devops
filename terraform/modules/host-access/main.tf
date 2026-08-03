terraform {
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = ">= 2.3.0"
    }
  }
}

# Discover the VM's external (Multipass) IP address. This is the source address
# of the VM's default route (the interface on the Multipass bridge).
data "external" "vm" {
  program = ["bash", "${path.module}/scripts/vm_ip.sh"]
}

# Discover the HAProxy unit's public address from Juju. HAProxy is a machine
# charm running in an LXD container inside the VM, so its address lives on the
# LXD bridge network and is not reachable from the host directly.
#
# The juju/juju Terraform provider does not surface per-unit IP addresses, so we
# query `juju status` via an external data source. The script always returns
# valid JSON (empty ip when the unit is not yet ready) so plans never fail.
data "external" "haproxy" {
  program = ["python3", "${path.module}/scripts/haproxy_addr.py"]

  query = {
    model = var.machine_model_name
    app   = var.app_name
  }
}

# Retrieve the self-signed CA certificate. The juju/juju Terraform provider
# cannot run actions, so we invoke `get-ca-certificate` on the leader unit via
# the juju CLI. The script always returns valid JSON (empty ca when the action
# is not yet available) so plans never fail while the app is settling.
data "external" "ca_cert" {
  program = ["python3", "${path.module}/scripts/ca_cert.py"]

  query = {
    model = var.certificates_model_name
    app   = var.certificates_app_name
  }
}
