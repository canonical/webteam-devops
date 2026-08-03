#!/usr/bin/env python3
#
# Terraform external data source: report the HAProxy unit's public address.
#
# Input (stdin, JSON): {"model": "<juju-model>", "app": "<juju-app>"}
# Output (stdout, JSON): {"ip": "<addr>"}  (empty string if not yet available)
#
# HAProxy is a machine charm in an LXD container inside the VM. The juju/juju
# Terraform provider does not expose per-unit IPs, so we read them from Juju.
# We keep this fast and non-fatal: a bounded wait, and always valid JSON so
# `terraform plan` never breaks while the unit is settling.

import json
import shutil
import subprocess
import sys


def emit(ip=""):
    """Print the external data source contract and exit successfully."""
    print(json.dumps({"ip": ip}))
    sys.exit(0)


def run(cmd, timeout):
    """Run a subcommand with a hard external timeout.

    juju subcommands can block on controller connection well past their own
    --timeout flags, so we bound every call externally. Returns stdout on
    success, or None on any failure/timeout.
    """
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


def main():
    # --- Parse the query from stdin -------------------------------------------
    try:
        query = json.load(sys.stdin)
    except Exception:
        query = {}

    model = query.get("model") or "ingress-ps7-machine"
    app = query.get("app") or "haproxy"

    if shutil.which("juju") is None:
        emit()

    # --- Bounded wait for the unit to have an address -------------------------
    # Give Juju a short window to expose an address without blocking plans for
    # long. Non-fatal: we ignore the result and read the status regardless.
    run(
        [
            "juju", "wait-for", "unit", f"{app}/0",
            "--query", 'life=="alive" && agent-status=="idle"',
            "--timeout", "20s",
            "-m", model,
        ],
        timeout=20,
    )

    # --- Read the first unit's public-address ---------------------------------
    out = run(
        ["juju", "status", "-m", model, "--format=json"],
        timeout=10,
    )
    if not out:
        emit()
        return

    try:
        data = json.loads(out)
    except Exception:
        emit()
        return

    units = data.get("applications", {}).get(app, {}).get("units", {})
    for unit in units.values():
        addr = unit.get("public-address", "")
        if addr:
            emit(addr)

    emit()


if __name__ == "__main__":
    main()
