# Dishant CV Studio release

Source project: `C:\CODES\DISHANTcv`  
Package ID: `com.dishant.cvstudio`  
Version name comes from `package.json`; the SQLite release ledger allocates an increasing Android version code.

## Build

```powershell
# Debug APK for device installation
pwsh -File C:\Software\APK-DEV\Scripts\Build-Dishant-CV.ps1

# Signed APK for stores that take APKs
pwsh -File C:\Software\APK-DEV\Scripts\Build-Dishant-CV.ps1 -Task assembleRelease

# Signed AAB for Google Play, then queue for internal testing
pwsh -File C:\Software\APK-DEV\Scripts\Build-Dishant-CV.ps1 -Task bundleRelease -StageForStore google-play -Track internal

# Upload a queued AAB with configured Google Play service-account credentials
pwsh -File C:\Software\APK-DEV\Scripts\Build-Dishant-CV.ps1 -Task bundleRelease -StageForStore google-play -Track internal -Publish
```

Artifacts and checksum manifests are stored in `Factory\Development\Dishant-CV`. Store delivery copies are under `Transport\Queue\<store>`. Builds are also recorded in `Transport\Database\releases.sqlite3` and logged in `Logs\Builds`.

For the first signed build, create a unique key once with `Scripts\New-AndroidSigningKey.ps1 -AppName Dishant-CV -Alias upload`. Keep the key and password backed up separately; they are not recoverable from the APK. The release script asks for the password without saving it. Do not use the debug APK in a store submission.

## Store readiness

- **Google Play:** submit a signed AAB, complete Play App Signing, listing, policy and data safety declarations in Play Console, and configure an authorized service account at `Secrets\google-play-service-account.json` for script upload. New apps and updates need target API 36 from 31 August 2026. New personal accounts may also have a closed testing requirement.
- **PhonePe Appstore (formerly Indus):** use its developer console for account verification, app listing, policy declarations and binary upload. This factory can prepare and queue the signed APK/AAB; no verified upload credentials are configured.
- **Amazon:** no longer accepts new Android mobile-device apps. Fire tablet and Fire TV distribution remains a separate target.
- **APKPure:** manual signed-APK intake only; confirm its current developer process before submission.
- **F-Droid:** requires open-source eligibility, public source and metadata review. This private CV project is not ready for the main F-Droid repository.

The current debug build is not a store release. A release signing key, store developer account, listing, and (for Play API upload) service-account credentials are still required before external submission.
