"""Smoke-test release registration, checksums, and delivery status."""
import json
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "Scripts"))
import release_registry


class RegistrySmokeTest(unittest.TestCase):
    def test_build_stage_and_status_history(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            artifact = root / "app.aab"
            artifact.write_bytes(b"fixture bundle bytes")
            manifest = {
                "packageName": "com.example.app", "versionName": "1.0",
                "versionCode": 1, "artifactType": "aab",
                "app": "Example", "buildType": "release",
                "signingTool": "jarsigner",
                "signingCertificateSha256": "abc123",
                "buildLogPath": str(root / "build.log"),
                "artifactPath": str(artifact),
                "sha256": release_registry.digest(artifact),
                "stage": "queued", "status": "queued",
                "store": "google-play", "track": "internal",
            }
            manifest_path = root / "release.json"
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
            db = release_registry.connect(root / "history.sqlite3")
            try:
                release_registry.register(db, manifest_path)
                release_registry.mark(db, SimpleNamespace(
                    status="uploaded", receipt="edit-123",
                    package="com.example.app", version_code=1,
                    store="google-play", track="internal"))
                row = db.execute("""SELECT status,track,receipt,
                    signing_certificate_sha256,build_type,app_name,
                    build_log_path FROM releases""").fetchone()
                self.assertEqual(tuple(row),
                    ("uploaded", "internal", "edit-123", "abc123",
                     "release", "Example", str(root / "build.log")))
            finally:
                db.close()


if __name__ == "__main__":
    unittest.main()
