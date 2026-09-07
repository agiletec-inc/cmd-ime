import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class DistributionSigningTests(unittest.TestCase):
    def test_packaging_identity_policy(self):
        source = (ROOT / "apps/cmd-ime-swift/scripts/package.sh").read_text()
        function = "require_distribution_prerequisites() {" + source.split(
            "require_distribution_prerequisites() {", 1
        )[1].split("\nresolve_sparkle_public_key()", 1)[0]
        cases = [
            ("distribution", "CmdIME Self-Signed Publisher", False),
            ("distribution", "Apple Development: Example (TEST)", False),
            ("distribution", "-", False),
            ("distribution", "Developer ID Application: Example (TEST)", True),
            ("local", "-", True),
        ]
        for mode, identity, accepted in cases:
            with self.subTest(mode=mode, identity=identity):
                env = dict(os.environ, BUILD_MODE=mode, SIGN_IDENTITY=identity,
                           SPARKLE_PUBLIC_ED_KEY="test-public-key")
                result = subprocess.run(["bash"], input=function +
                                        "\nrequire_distribution_prerequisites\n",
                                        env=env, text=True, capture_output=True)
                self.assertEqual(result.returncode == 0, accepted)

    def test_signature_verifier_fails_closed(self):
        valid = ("Authority=Developer ID Application: Example (TESTTEAM)\n"
                 "TeamIdentifier=TESTTEAM\n"
                 "CodeDirectory v=20500 flags=0x10000(runtime)\n"
                 "Timestamp=Sep 7, 2026\n")
        cases = [
            (valid, "TESTTEAM", "0", True),
            (valid.replace("Developer ID Application:", "Apple Development:"), "TESTTEAM", "0", False),
            (valid.replace("Developer ID Application:", "Self Signed:"), "TESTTEAM", "0", False),
            (valid.replace("(runtime)", "(none)"), "TESTTEAM", "0", False),
            (valid.replace("Timestamp=Sep 7, 2026\n", ""), "TESTTEAM", "0", False),
            (valid, "WRONGTEAM", "0", False),
            (valid, "", "0", False),
            (valid, "TESTTEAM", "1", False),
        ]
        with tempfile.TemporaryDirectory() as temporary:
            mock = Path(temporary) / "codesign"
            mock.write_text('#!/bin/bash\nif [[ "$1" == "--verify" ]]; then exit "$VERIFY_EXIT"; fi\nprintf "%s" "$SIGNATURE_FIXTURE" >&2\n')
            mock.chmod(0o755)
            for signature, team, verification, accepted in cases:
                with self.subTest(team=team, signature=signature, verification=verification):
                    env = dict(os.environ, CMDIME_EXPECTED_TEAM_ID=team,
                               SIGNATURE_FIXTURE=signature, VERIFY_EXIT=verification)
                    env["PATH"] = temporary + os.pathsep + env["PATH"]
                    result = subprocess.run(["bash", str(ROOT / ".github/scripts/verify-distribution.sh"),
                                             "fixture.app"], env=env, text=True, capture_output=True)
                    self.assertEqual(result.returncode == 0, accepted, result.stderr)


if __name__ == "__main__":
    unittest.main(verbosity=2)
