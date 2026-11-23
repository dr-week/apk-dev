# Android store delivery guide

## Store support and practical requirements

| Store | Artifact and route | Current fit |
| --- | --- | --- |
| Google Play | Signed AAB; first listing/setup in Play Console, then optional Publishing API automation | Supported. A full-distribution developer account costs a one-time US$25. Starting 31 Aug 2026, submissions must target API 36+. New personal accounts created after 13 Nov 2023 must complete a closed test with 12 testers opted in for 14 continuous days before applying for production access. |
| PhonePe Appstore (formerly Indus) | APK or AAB through PhonePe Appstore Developer Console; API docs are available | A free-start listing path is advertised. The portal offers listing import and binary upload; complete mobile/email and identity verification, policy declarations, and review there. No upload credentials are configured in this factory. |
| Amazon Appstore | APK/AAB through Developer Console; Submission API supports APK updates to existing listings | Fire tablets, Fire TV, and Fire TV built-in remain supported. Amazon discontinued the Android mobile-device store on 20 Aug 2025 and stopped accepting new mobile-targeted apps on 20 Feb 2025, so this is not a route for general Android phones. Developer registration is free. |
| APKPure | Signed APK through its current developer intake | No verified public upload API is configured. Check its official developer channel and terms before using; the factory can stage a signed APK and checksum for manual intake. |
| F-Droid main repository | Public source repository, FOSS license, build metadata and review; F-Droid builds/signs | Not currently eligible from this private project as-is. F-Droid requires free/open-source software and prefers source builds. A binary-only APK handoff is not its normal intake. A separate repository has different setup/maintenance requirements. |
| Direct/manual | Signed APK and SHA-256 checksum | Suitable for a controlled download site, with a safe update and signing-key continuity plan. |

“Free” availability varies: Google Play charges the one-time registration fee; Amazon registration is free; check current PhonePe and other marketplace terms in their developer portals. App review, developer identity, store listing content, privacy/policy forms, and production decisions remain account-owner tasks. A local script cannot create those accounts or make legal declarations for the developer.

## Automated Google Play path

The factory can prepare and upload an AAB to an existing app listing and track using the Publishing API. First upload, listing creation, declarations, Play App Signing enrollment, and required review steps must be completed in Play Console. API access requires an enabled Google Play Developer API, a service account granted appropriate Play Console access, and its JSON key stored at `Secrets\google-play-service-account.json`.

```powershell
# Build an upload-signed App Bundle (prompts for the app-key password)
Scripts\Build-The-Social-Base.ps1 -Task bundleRelease

# Stage the generated AAB for internal testing
Scripts\Stage-AndroidRelease.ps1 -ArtifactPath <AAB-path> -Store google-play -Track internal

# Preview first; no upload occurs without -Publish
Scripts\Publish-GooglePlay.ps1 -ArtifactPath <queued-AAB-path> -Track internal

# Upload and commit to the selected track after credentials and listing are ready
Scripts\Publish-GooglePlay.ps1 -ArtifactPath <queued-AAB-path> -Track internal -Publish
```

The API script refuses production unless `-ConfirmProduction` is supplied. Production publishing through the API does not complete Play Console declarations, account eligibility, or policy review. Keep production review in Play Console. `Scripts\Release-The-Social-Base-GooglePlay.ps1` combines build, staging, and dry-run; add `-Publish` only when the listing and service account are ready.

## Versioning, signing, and staged artifacts

- App version name comes from the source `package.json` (`0.1.0` currently); a centralized SQLite ledger assigns the next unused Android version code.
- Debug builds are for local installation only. Store staging rejects debug builds.
- Release builds use the per-app upload key under `Secrets\The-Social-Base\`. Generate it once with `Scripts\New-AndroidSigningKey.ps1 -AppName The-Social-Base -Alias upload -GenerateProtectedPassword`; keep a secure, separate backup. Never check it into source control.
- `Factory\Development\The-Social-Base` holds build artifacts and JSON manifests; manifests record package, version, build type, signing certificate fingerprint, and SHA-256. `Transport\Queue` holds store-specific staged copies. `Transport\Database\releases.sqlite3` is the searchable release history.
- `Scripts\Clean-AndroidTemp.ps1` removes scratch files only. Use `-IncludeDownloads` only after verifying that cached downloads are no longer needed.

## Official references

- [Google Play target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878)
- [Google Play registration and fee](https://support.google.com/googleplay/android-developer/answer/6112435)
- [Google Play testing requirements for new personal accounts](https://support.google.com/googleplay/android-developer/answer/14151465)
- [Google Play Developer API setup](https://developers.google.com/android-publisher/getting_started)
- [Google Play Publishing API limitations](https://developers.google.com/android-publisher/edits)
- [Android app signing](https://developer.android.com/studio/publish/app-signing)
- [PhonePe Appstore developer portal](https://developer.indusappstore.com/)
- [PhonePe APK/AAB upload guidance](https://developer.indusappstore.com/docs/apks)
- [PhonePe developer policy and onboarding](https://www.phonepeappstore.com/developer-policy/)
- [Amazon's Android-device store change](https://developer.amazon.com/apps-and-games/blogs/2025/02/upcoming-changes-to-amazon-appstore-for-android-devices-and-coins-program)
- [Amazon Appstore submission](https://developer.amazon.com/docs/app-submission/submitting-apps-to-amazon-appstore.html)
- [Amazon Submission API scope](https://developer.amazon.com/docs/app-submission-api/overview.html)
- [F-Droid submission guide](https://f-droid.org/docs/Submitting_to_F-Droid_Quick_Start_Guide/)
- [F-Droid inclusion policy](https://f-droid.org/en/docs/Inclusion_Policy/)
