output "gateway_ip" {
  description = "Discovered external IP of the gateway that HAProxy routes to."
  value       = module.demos_ps7.gateway_ip
}

output "pr_hostnames" {
  description = "Map of PR app name to its routed hostname."
  value       = { for name, cfg in var.pr_apps : name => cfg.hostname }
}
