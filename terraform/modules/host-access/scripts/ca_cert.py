#!/usr/bin/env python3
#
# Terraform external data source: report the self-signed CA certificate.
#
# Input (stdin, JSON):  {"model": "<juju-model>", "app": "<juju-app>"}
# Output (stdout, JSON): {"ca": "<pem>"}  (empty string if not yet available)
#
# The juju/juju Terraform provider cannot run actions, so we invoke the
# `get-ca-certificate` action on the self-signed-certificates leader via the
# juju CLI. Kept non-fatal and always valid JSON so `terraform plan` never
# breaks while the app is still settling.
#
# On the first `terraform apply`, the juju_application resources return as soon
# as the apps are *created*, not once their units are active/idle. The action is
# therefore not yet available and would return empty, leaving the CA blank until
# a second apply. To make the first apply succeed we poll the action until it
# returns a certificate or a bounded deadline elapses.


import json
import shutil
import subprocess
import sys
import time


WAIT_SECONDS = 240
POLL_INTERVAL = 15
ACTION_TIMEOUT = 60


def emit(ca=""):
    """
    Print the external data source contract and exit successfully.
    """
    print(json.dumps({"ca": ca}))
    sys.exit(0)


def run(cmd, timeout):
    """
    Run a subcommand with a hard external timeout; None on any failure.
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


def fetch_ca(model, app):
    """
    Run the action once; return the CA PEM or "" if not yet available.
    `juju run <app>/leader get-ca-certificate` — the action returns the PEM
    under results.ca-certificate. --format=json keys output by unit name.
    """
    out = run(
        ["juju", "run", f"{app}/leader", "get-ca-certificate",
         "-m", model, "--format=json"],
        timeout=ACTION_TIMEOUT,
    )
    if not out:
        return ""

    try:
        data = json.loads(out)
    except Exception:
        return ""

    # Output shape: {"<app>": {"results": {"ca-certificate": "<pem>"}, ...}}
    for unit in data.values():
        ca = unit.get("results", {}).get("ca-certificate", "")
        if ca:
            return ca
    return ""


def main():
    try:
        query = json.load(sys.stdin)
    except Exception:
        query = {}

    model = query.get("model")
    app = query.get("app")

    if shutil.which("juju") is None:
        emit()

    # Poll until the action yields a certificate or the deadline passes. This
    # lets the first apply pick up the CA once the leader settles, instead of
    # returning empty and needing a second apply. Always non-fatal: on timeout
    # we emit an empty CA and exit 0 so the plan/apply still succeeds.
    deadline = time.monotonic() + WAIT_SECONDS
    attempt = 0
    while True:
        attempt += 1
        ca = fetch_ca(model, app)
        if ca:
            emit(ca)
        if time.monotonic() + POLL_INTERVAL >= deadline:
            emit()
        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    main()
