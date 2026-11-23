"""Shared SQLite release index for Android artifacts built by this folder."""
import argparse
import hashlib
import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path


def connect(path):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    db = sqlite3.connect(path)
    db.row_factory = sqlite3.Row
    db.execute("""CREATE TABLE IF NOT EXISTS releases (
        id INTEGER PRIMARY KEY, app_name TEXT NOT NULL, package TEXT NOT NULL,
        version_name TEXT NOT NULL, version_code INTEGER NOT NULL,
        build_type TEXT NOT NULL, artifact_type TEXT NOT NULL,
        artifact_path TEXT NOT NULL, sha256 TEXT NOT NULL,
        signing_tool TEXT, signing_certificate_sha256 TEXT,
        stage TEXT NOT NULL, status TEXT NOT NULL, store TEXT, track TEXT,
        receipt TEXT, manifest_path TEXT NOT NULL, build_log_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(package, version_code, artifact_type, stage, store, track))""")
    db.commit()
    return db


def digest(path):
    sha = hashlib.sha256()
    with Path(path).open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            sha.update(block)
    return sha.hexdigest()


def register(db, manifest_path):
    manifest = json.loads(Path(manifest_path).read_text(encoding="utf-8-sig"))
    required = ("packageName", "versionName", "versionCode", "artifactType",
                "artifactPath", "sha256", "stage", "status")
    missing = [key for key in required if key not in manifest]
    if missing:
        raise ValueError("Manifest missing: " + ", ".join(missing))
    artifact = Path(manifest["artifactPath"]).resolve(strict=True)
    actual = digest(artifact)
    if actual != manifest["sha256"].lower():
        raise ValueError(f"SHA-256 mismatch: {artifact}")
    now = datetime.now(timezone.utc).isoformat()
    values = (manifest.get("app", manifest["packageName"]), manifest["packageName"],
              manifest["versionName"], int(manifest["versionCode"]),
              manifest.get("buildType", "release"), manifest["artifactType"],
              str(artifact), actual, manifest.get("signingTool"),
              manifest.get("signingCertificateSha256"), manifest["stage"],
              manifest["status"], manifest.get("store"), manifest.get("track"),
              manifest.get("receipt"), str(Path(manifest_path).resolve()),
              manifest.get("buildLogPath"), now, now)
    db.execute("""INSERT INTO releases(app_name,package,version_name,version_code,
        build_type,artifact_type,artifact_path,sha256,signing_tool,
        signing_certificate_sha256,stage,status,store,track,receipt,manifest_path,
        build_log_path,created_at,updated_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        ON CONFLICT(package,version_code,
        artifact_type,stage,store,track) DO UPDATE SET artifact_path=excluded.artifact_path,
        sha256=excluded.sha256,status=excluded.status,track=excluded.track,
        receipt=excluded.receipt,manifest_path=excluded.manifest_path,
        build_log_path=excluded.build_log_path,
        updated_at=excluded.updated_at""", values)
    db.commit()
    print(f"Registered {manifest['packageName']} {manifest['versionName']} ({manifest['stage']}).")


def mark(db, args):
    now = datetime.now(timezone.utc).isoformat()
    result = db.execute("""UPDATE releases SET status=?,receipt=?,updated_at=?
        WHERE package=? AND version_code=? AND store=? AND track IS ? AND stage='queued'""",
        (args.status, args.receipt or None, now, args.package,
         args.version_code, args.store, args.track or None))
    if result.rowcount != 1:
        raise ValueError("No matching queued release found.")
    db.commit()
    print(f"Marked {args.package} code {args.version_code}: {args.status}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", required=True, type=Path)
    commands = parser.add_subparsers(dest="action", required=True)
    add = commands.add_parser("register")
    add.add_argument("--manifest", required=True, type=Path)
    update = commands.add_parser("mark")
    update.add_argument("--package", required=True)
    update.add_argument("--version-code", required=True, type=int)
    update.add_argument("--store", required=True)
    update.add_argument("--track", default="")
    update.add_argument("--status", required=True)
    update.add_argument("--receipt", default="")
    commands.add_parser("list")
    args = parser.parse_args()
    with connect(args.database) as db:
        if args.action == "register":
            register(db, args.manifest)
        elif args.action == "mark":
            mark(db, args)
        else:
            for row in db.execute("SELECT * FROM releases ORDER BY updated_at DESC"):
                print(json.dumps(dict(row), ensure_ascii=False))


if __name__ == "__main__":
    main()
