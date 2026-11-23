# Android App Factory index

- [Workflow and commands](WORKFLOW.md)
- [Store routes and current requirements](STORES.md)
- [Release checklist](RELEASE_CHECKLIST.md)
- [Store Control Center UI/product spec](STORE_CONTROL_CENTER_SPEC.md)
- [Store Control Center implementation](../Control-Center/README.md)
- [Scripts and toolchain notes](../Scripts/README.md)
- [Registered source projects](../Apps/registry.json)
- [Development APK/AABs](../Factory/Development/)
- [Store upload queue](../Transport/Queue/)
- [Release ledger](../Transport/Database/releases.sqlite3)
- [Credentials and app signing keys](../Secrets/README.md)
- [Temporary file cleanup](../Scripts/Clean-AndroidTemp.ps1)

## Dishant CV Studio

- Android package: `com.dishant.cvstudio`
- Display name: `Dishant CV Studio`
- Source version: `1.0.0` (version name); version code comes from the SQLite ledger.
- Build/upload entry point: `Scripts\Build-Dishant-CV.ps1`
- App-specific workflow: [Dishant CV Studio release](DISHANT-CV.md)

## The Social Base

- Android package: `com.followdesk.app`
- Display name: `The Social Base`
- Source version: `0.1.0` (version name); Android version code is allocated by the SQLite ledger.
- Build entry point: `Scripts\Build-The-Social-Base.ps1` or from source `npm run android:apk`.
- Google Play one-command draft path: `Scripts\Release-The-Social-Base-GooglePlay.ps1` (dry-run unless `-Publish` is given).
