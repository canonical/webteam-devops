#!/usr/bin/env python3
#
# Terraform external data source: create default namespace in Temporal server..
#
# Input (stdin, JSON): {"model": "<juju-model>", "app": "<juju-app>"}
# Output (stdout, JSON): {}
#
# The juju/juju Terraform provider can run actions, but they do not wait for the
# application and relations to be ready and the `apply` may fail, so we invoke the
# action via the juju CLI with polling.
# Kept non-fatal and always valid JSON so `terraform plan` never breaks while the
# app is still settling.
#
# On the first `terraform apply`, the juju_application resources return as soon
# as the apps are *created*, not once their units are active/idle. The action is
# therefore not yet available and could fail, requiring a second apply.
# To make the first apply succeed we poll the action until it succeds or a
# bounded deadline elapses.


import json
import shutil
import subprocess
import sys
import time
import typing


WAIT_SECONDS = 600
POLL_INTERVAL = 15
ACTION_TIMEOUT = 60

NAMESPACE_ALREADY_EXISTS = "Namespace already exists"


def emit():
    """
    Exit successfully.
    """
    print(json.dumps({}))
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


def create_temporal_namespace(model, app) -> bool:
    """
    Run the action once:
    `juju run temporal-admin-k8s/leader cli ...`

    Returns a boolean indicating if the action succeeded or not.
    """
    out = run(
        ["juju", "run", f"{app}/leader", "cli",
         "args=\"operator namespace create --namespace default --retention 1d\"",
         "-m", model, "--format=json"],
        timeout=ACTION_TIMEOUT,
    )
    if not out:
        return False

    try:
        data = json.loads(out)
    except Exception:
        return False

    # Output successful shape: {
    #     "<unit>": {
    #         "results": { "output": <out>, "result": "command succeeded" },
    #         "status": "completed" | "failed"
    #     },
    #     ...
    # }
    # A failed action gives back no results.output or results.result, but contains
    # a "message" key with the error.
    for unit in data.values():
        output = unit.get("results", {}).get("output", None)
        if output:
            return True
        # if the error was that the namespace already exists that's fine
        message = typing.cast(str, unit.get("message"))
        if NAMESPACE_ALREADY_EXISTS in message:
            return True

    return False


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
        namespace_created = create_temporal_namespace(model, app)
        if namespace_created or time.monotonic() + POLL_INTERVAL >= deadline:
            emit()
        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    main()
