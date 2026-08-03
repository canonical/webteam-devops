#!/usr/bin/env bash
#
# Terraform external data source: report the VM's external (Multipass) IP.
#
# The external IP is the source address of the default route — i.e. the NIC on
# the Multipass bridge, which is the address the host can reach. Always emits
# valid JSON: {"ip": "<addr>"} (empty string if it cannot be determined).
set -euo pipefail

# The external provider passes the query as JSON on stdin; we don't need it here,
# but consume it so the program behaves well.
cat >/dev/null || true

ip_addr="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')"

# Emit a JSON object with string values, as required by the external provider.
printf '{"ip":"%s"}\n' "${ip_addr:-}"
