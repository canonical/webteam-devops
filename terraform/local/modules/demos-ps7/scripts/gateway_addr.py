#!/usr/bin/env python3
#
# Terraform external data source: report the gateway-api-integrator gateway's
# external (LoadBalancer) IP address.
#
# Input (stdin, JSON):  {"model": "<juju-model>", "app": "<juju-app>"}
# Output (stdout, JSON): {"ip": "<addr>"}  (empty string if not yet available)
#
# The gateway-api-integrator (gateway-class=traefik) publishes a Kubernetes
# Gateway whose external address is assigned by the LoadBalancer only once the
# charm has settled. The juju/juju Terraform provider does not surface that
# address, so we read it from the charm's unit status message ("Gateway
# addresses: <ip>") via `juju status`, mirroring the host-access module scripts
# (haproxy_addr.py / ca_cert.py): always valid JSON, non-fatal, and a bounded
# poll so the FIRST `terraform apply` succeeds instead of needing a second one.

import json
import re
import shutil
import subprocess
import sys
import time


WAIT_SECONDS = 240
POLL_INTERVAL = 15
CMD_TIMEOUT = 30


def emit(ip=""):
    """Print the external data source contract and exit successfully."""
    print(json.dumps({"ip": ip}))
    sys.exit(0)


def run(cmd, timeout):
    """Run a subcommand with a hard external timeout; None on any failure."""
    try:
        result = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            timeout=timeout,
            check=False,
        )
    except (subprocess.TimeoutExpired, OSError):
        return None
    if result.returncode != 0:
        return None
    return result.stdout.decode("utf-8", "replace")


def fetch_ip(model, app):
    """Return the gateway's external LoadBalancer IP, or "" if not yet available.

    gateway-api-integrator surfaces the address the traefik controller assigns
    (via the LoadBalancer, MetalLB in this environment) in its unit status
    message, e.g. ``Gateway addresses: 10.0.0.42 (enforce-https is set to
    false)``. The juju/juju Terraform provider does not expose that message, so
    we read it from ``juju status`` and extract the first IPv4.

    Returns "" while the gateway has no address yet (charm still in a
    WaitingStatus), which keeps plan/apply non-fatal.
    """
    out = run(
        ["juju", "status", "-m", model, "--format=json"],
        timeout=CMD_TIMEOUT,
    )
    if not out:
        return ""

    try:
        data = json.loads(out)
    except Exception:
        return ""

    application = data.get("applications", {}).get(app, {})

    # Prefer the unit workload-status message (where the charm sets it), then
    # fall back to the application-status message.
    messages = []
    for unit in application.get("units", {}).values():
        message = unit.get("workload-status", {}).get("message", "")
        if message:
            messages.append(message)
    app_message = application.get("application-status", {}).get("message", "")
    if app_message:
        messages.append(app_message)

    for message in messages:
        if "Gateway addresses:" not in message:
            continue
        match = re.search(r"\b(\d{1,3}(?:\.\d{1,3}){3})\b", message)
        if match:
            return match.group(1)

    return ""


def main():
    try:
        query = json.load(sys.stdin)
    except Exception:
        query = {}

    model = query.get("model") or "demos"
    app = query.get("app") or "gateway-api"

    if shutil.which("juju") is None:
        emit()

    # Poll until an address is available or the deadline passes. Non-fatal: on
    # timeout we emit an empty ip and exit 0 so plan/apply still succeed while
    # the gateway is still settling.
    deadline = time.monotonic() + WAIT_SECONDS
    while True:
        ip = fetch_ip(model, app)
        if ip:
            emit(ip)
        if time.monotonic() + POLL_INTERVAL >= deadline:
            emit()
        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    main()
