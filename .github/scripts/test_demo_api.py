"""Regression tests for operation-specific controller polling."""

import argparse
from pathlib import Path
import textwrap
import types
import unittest
from unittest.mock import patch

workflow_path = Path(__file__).resolve().parents[1] / "workflows/demo-api.yaml"
source = textwrap.dedent(
    workflow_path.read_text().split("<<'PY'\n", 1)[1].split("          PY\n", 1)[0]
)
demo_api = types.ModuleType("demo_api")
exec(compile(source, str(workflow_path), "exec"), demo_api.__dict__)


class PollTests(unittest.TestCase):
    def setUp(self):
        self.args = argparse.Namespace(
            repository="canonical/example",
            pr_number=29,
            timeout=10,
            interval=1,
            api_url="https://demos.example",
            key="test-key",
            connect_url=None,
            insecure=False,
        )

    def test_only_operation_specific_states_succeed(self):
        states = ("ready", "deployed", "succeeded", "success", "deleted", "destroyed")
        for desired_absence in (False, True):
            accepted = (
                {"deleted", "destroyed"} if desired_absence else {"ready", "deployed"}
            )
            for state in states:
                with self.subTest(desired_absence=desired_absence, state=state):
                    response = {"state": state}
                    with (
                        patch.object(demo_api, "request", return_value=response),
                        patch.object(demo_api.time, "monotonic", side_effect=[0, 0, 11]),
                        patch.object(demo_api.time, "sleep"),
                    ):
                        if state in accepted:
                            self.assertEqual(
                                demo_api.poll(self.args, desired_absence=desired_absence),
                                response,
                            )
                        else:
                            with self.assertRaisesRegex(demo_api.ApiError, "Timed out"):
                                demo_api.poll(self.args, desired_absence=desired_absence)

    def test_deployment_waits_past_stale_cleanup_state(self):
        with (
            patch.object(
                demo_api,
                "request",
                side_effect=[{"state": "destroyed"}, {"state": "ready"}],
            ),
            patch.object(demo_api.time, "monotonic", return_value=0),
            patch.object(demo_api.time, "sleep") as sleep,
        ):
            self.assertEqual(demo_api.poll(self.args), {"state": "ready"})
            sleep.assert_called_once_with(1)

    def test_not_found_succeeds_only_for_cleanup(self):
        for desired_absence in (False, True):
            with self.subTest(desired_absence=desired_absence):
                with (
                    patch.object(
                        demo_api, "request", side_effect=demo_api.ApiError("missing", 404)
                    ),
                    patch.object(demo_api.time, "monotonic", return_value=0),
                ):
                    if desired_absence:
                        self.assertEqual(
                            demo_api.poll(self.args, desired_absence=True)["state"],
                            "destroyed",
                        )
                    else:
                        with self.assertRaisesRegex(demo_api.ApiError, "missing"):
                            demo_api.poll(self.args)

    def test_terminal_failures_raise_for_both_operations(self):
        for desired_absence in (False, True):
            for state in demo_api.TERMINAL_FAILURE:
                with self.subTest(desired_absence=desired_absence, state=state):
                    with (
                        patch.object(
                            demo_api,
                            "request",
                            return_value={"state": state, "message": "controller failure"},
                        ),
                        patch.object(demo_api.time, "monotonic", return_value=0),
                    ):
                        with self.assertRaisesRegex(
                            demo_api.ApiError, "controller failure"
                        ):
                            demo_api.poll(self.args, desired_absence=desired_absence)


if __name__ == "__main__":
    unittest.main()
