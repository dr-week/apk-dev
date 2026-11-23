# Shared Android release workflow

## The Social Base quick build

From the project or the factory:

```powershell
npm run android:apk
# or choose a build type directly
pwsh -File C:\Software\APK-DEV\Scripts\Build-The-Social-Base.ps1 -Task assembleDebug
```

The script builds the web assets, syncs Capacitor, reads the version name from the project `package.json`, allocates the next version code from the central SQLite ledger, builds with the project's pinned Gradle version, verifies the signature/checksum, and copies a named artifact and manifest to `Factory\Development\The-Social-Base`. A debug APK is for device installation, not store upload. For the exact release steps see [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md).

## Project setup

Register any Android Gradle project, regardless of business domain:

```powershell
Scripts\Register-AndroidApp.ps1 -Name MyApp -ProjectPath C:\Projects\MyApp
Scripts\Build-AndroidApp.ps1 -Name MyApp
```

The project must provide `gradlew.bat` at its root or in `android\`. Use `-Task bundleRelease` for an AAB; the default `assembleRelease` produces APKs. Product flavors work too, such as `-Task bundleFreeRelease`. Run web/framework-specific build and sync steps in the app repository first (for example, Capacitor `build` and `cap sync android`). This shared factory does not alter app source or infer framework-specific commands. Flutter, Unity, native NDK/CMake, and other frameworks may need their own framework toolchain and build step; install those centrally only when an app needs them. Run these scripts in PowerShell 7 (`pwsh`).

Release artifacts are copied to `Factory\Development\<name>` with a JSON manifest and SHA-256 checksum. The SQLite registry records package, version, artifact, checksum, stage, store, and timestamps. Version name/code come from the built Android artifact. Android requires the version code to increase for each update; this tool records it and does not silently modify an app's versioning.

To ask the shared ledger for the next unused code, run `Scripts\Get-NextVersionCode.ps1 -PackageName com.example.app`, then set that code in the app's own version config before building.

## Store transport

Stage only a signed artifact for the chosen destination:

```powershell
Scripts\Stage-AndroidRelease.ps1 -ArtifactPath C:\path\MyApp.aab -Store google-play
Scripts\Stage-AndroidRelease.ps1 -ArtifactPath C:\path\MyApp.apk -Store amazon
```

Staging verifies SHA-256, checks artifact type, copies it to `Transport\Queue\<store>`, and records it. Staging is not a store upload. Store review and listing declarations remain developer-console steps. When upload succeeds, save the receipt/status:

```powershell
Scripts\Set-ReleaseStatus.ps1 -PackageName com.example.app -VersionCode 12 -Store google-play -Status uploaded -Receipt "Play edit or release URL"
```

For Google Play, `Scripts\Publish-GooglePlay.ps1 -ArtifactPath <queued-aab>` previews the target track. The API path requires `Secrets\google-play-service-account.json` and Play Console authorization. Add `-Publish` for upload; production additionally requires `-ConfirmProduction`. Set notes with `-ReleaseNotes`.

## Signing

Configure each app's signing in its source project or the CI secret store. Keep production keystores under `Secrets` only if they must live on this machine, and keep passwords out of scripts, JSON, command history, and manifests. Back up keys securely. Google Play App Signing requires an upload-signed AAB for new apps. APK stores generally need a signed APK. Each independently published app needs a stable application ID and signing lineage.

To generate a separate upload key for one app, run `Scripts\New-AndroidSigningKey.ps1 -AppName MyApp`; `keytool` asks for passwords interactively. Add signing properties to that app's own Gradle user properties or CI secret store. Never copy key bytes into the shared app registry.

## Toolchain maintenance

Run `Scripts\Set-Android-Dev-Environment.ps1` once, then open a new terminal. On a fresh machine run `Scripts\Install-Android-Toolchain.ps1`; on this preconfigured machine use `Scripts\Update-Android-Toolchain.ps1` to refresh Android CLI/SDK packages and pinned Bundletool. Project wrappers own Gradle versions; their wrapper distribution is downloaded and verified by Gradle itself. Keep downloads under `Cache\Downloads` and scratch under `Temp`; maintenance scripts clean only files they create.
