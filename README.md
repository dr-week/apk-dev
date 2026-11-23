# Android App Factory

Shared Android build, packaging, signing, and store-delivery toolchain. App source code stays in its own repository; this folder holds the shared toolchain, the release scripts, the local Control Center dashboard, and the delivery records that tie them together.

Registered apps today:

| Factory name | Display name | Android package | Source project |
| --- | --- | --- | --- |
| `SMKD` | Stock Market Ka Don | — | `C:\CODES\money\mm` |
| `The-Social-Base` | The Social Base | `com.followdesk.app` | `C:\CODES\001\UNFOLLOWER` |
| `Dishant-CV` | Dishant CV Studio | `com.dishant.cvstudio` | `C:\CODES\DISHANTcv` |

Source paths are absolute and machine-specific; see `Apps\registry.json`.

## Start here

1. For Dishant CV Studio, run `pwsh -File Scripts\Build-Dishant-CV.ps1`; its versioned development APK goes to `Factory\Development\Dishant-CV`.
2. For store builds, create the app-specific signing key once with `Scripts\New-AndroidSigningKey.ps1 -AppName Dishant-CV -Alias upload`, then build a signed APK with `-Task assembleRelease` or a Play bundle with `-Task bundleRelease`.
3. Stage it: `pwsh -File Scripts\Stage-AndroidRelease.ps1 -ArtifactPath <path> -Store google-play`.
4. Preview Play delivery with `Scripts\Publish-GooglePlay.ps1`; add `-Publish` to commit an upload and `-ConfirmProduction` for production.

See [`Docs\INDEX.md`](Docs/INDEX.md) for the folder map, [`Docs\WORKFLOW.md`](Docs/WORKFLOW.md) for commands, [`Docs\STORES.md`](Docs/STORES.md) for current store routes, and [`Docs\RELEASE_CHECKLIST.md`](Docs/RELEASE_CHECKLIST.md) before public release. The shared SQLite ledger is `Transport\Database\releases.sqlite3`.

## Requirements

- Windows with PowerShell 7 (`pwsh`)
- JDK 21 and the Android SDK command-line tools (installed by `Scripts\Install-Android-Toolchain.ps1`)
- Each app's own Gradle wrapper and language toolchain (Node, Flutter, NDK, …) as needed

On an already provisioned machine, run `Scripts\Set-Android-Dev-Environment.ps1` once and open a new terminal. On a fresh machine, run `Scripts\Install-Android-Toolchain.ps1`; use `Scripts\Update-Android-Toolchain.ps1` (or `Update-Android-Dev.ps1`) to refresh the SDK and pinned Bundletool.

## Layout

- `Apps\registry.json`: names, display names and source project paths, plus `Apps\templates\store-listing.json`.
- `Scripts`: PowerShell build, signing, staging, publishing and maintenance scripts, with the shared `release_registry.py` ledger helper.
- `Control-Center`: local-first Vite/TypeScript release dashboard (Zuari + SCSS, no React). Run `pnpm install` then `pnpm dev` inside it.
- `Docs`: workflow, store routes, research, release checklist and the Control Center spec.
- `Tests`: release/device check records and the ledger unit test (`test_release_registry.py`).
- `Factory\Development`: locally built, versioned APKs/AABs with JSON manifests.
- `Transport\Queue`, `Uploaded`, `Database`, `Stores`: staged delivery copies, receipts, SQLite history and store notes.
- `Android-SDK`, `Android-AVD`, `Android-CLI`, `Gradle`, `Tools`: shared installed toolchain, emulator and verified helper binaries.
- `Cache`, `Temp`, `Logs`, `Secrets`, `Config`, `Backups`: downloads, scratch, logs, credentials and non-secret configuration.

## What this repository does not contain

The installed SDK/emulator/Gradle distributions, Bundletool jar, `node_modules`, built artifacts, staged queues, the SQLite ledger, logs and every secret are ignored by Git. Reinstall toolchains with the scripts above; regenerate artifacts by building. Signing keys live only under `Secrets\<app-name>` and are never committed, copied into artifacts, or shared between apps.

The factory runs each project's pinned Gradle version, using its matching preinstalled distribution when present and otherwise the project's wrapper. It does not modify app source or infer framework-specific build steps.
