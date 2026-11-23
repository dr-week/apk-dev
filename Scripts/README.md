# Script index

Run scripts with PowerShell 7 (`pwsh -File ...`). Register project paths in `Apps\registry.json`; source code stays in its existing repository.

- `Register-AndroidApp.ps1`: register Gradle wrapper project.
- `Build-The-Social-Base.ps1`: build/sync this workspace's app, allocate the next version code, and copy the named APK/AAB into the factory.
- `Build-Dishant-CV.ps1`: build this workspace's CV app and optionally stage/upload its release artifact.
- `Release-The-Social-Base-GooglePlay.ps1`: build, queue, and dry-run a Play release; add `-Publish` to upload, and `-ConfirmProduction` for a production track.
- `Build-AndroidApp.ps1`: release APK or AAB, log, inspect manifest, verify signature, checksum, and record.
- `Stage-AndroidRelease.ps1`: verify and copy an artifact into a store queue.
- `Publish-GooglePlay.ps1`: dry-run by default; API upload requires `-Publish` and credentials.
- `Set-ReleaseStatus.ps1`, `Get-AndroidReleaseReport.ps1`, `Get-NextVersionCode.ps1`: update and inspect history.
- `Verify-AndroidArtifact.ps1`, `New-AndroidSigningKey.ps1`: signature validation and per-app key generation.
- `Set-Android-Dev-Environment.ps1`, `Install-Android-Toolchain.ps1`, `Update-Android-Toolchain.ps1`, `Clean-AndroidTemp.ps1`: environment, initial setup, updates, and safe cleanup.

Run `Build-The-Social-Base.ps1` for this project. Release tasks prompt for the upload-key password; the debug task does not need a production key. `Update-Android-Dev.ps1` updates the shared Android SDK and pinned Bundletool, then cleans temporary files. Project Gradle versions remain pinned per wrapper; the factory uses its matching installed distribution when present.

The `*-SMKD-*` launchers are retained as legacy shortcuts for the stock market project.
