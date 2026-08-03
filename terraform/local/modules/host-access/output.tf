output "vm_ip" {
  description = "External (Multipass) IP address of the VM, reachable from the host."
  value       = data.external.vm.result.ip
}

output "haproxy_ip" {
  description = "Public address of the HAProxy unit inside the VM (LXD network)."
  value       = data.external.haproxy.result.ip
}

output "ports" {
  description = "Comma-separated list of TCP ports forwarded from the VM to HAProxy."
  value       = var.ports
}

output "hostnames" {
  description = "Hostnames served by the ingress."
  value       = var.hostnames
}

output "ca_certificate" {
  description = "PEM-encoded CA certificate from the self-signed-certificates charm."
  value       = data.external.ca_cert.result.ca
}
