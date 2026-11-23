# Release checklist

## Before creating a public release

- [ ] Confirm `com.followdesk.app` is the permanent package ID and the developer owns the name/branding. Package IDs and signing identity must remain stable across updates.
- [ ] Finish the feature work and update the source `package.json` version name. The factory allocates the next unused version code.
- [ ] Create and back up the app-specific upload key once. Never use the debug build key for public releases.
- [ ] Review Android permissions, target API, privacy/data use, account/login behaviour, external-service claims, icons, screenshots, support contact, and a public privacy-policy URL.
- [ ] Test the built release on a current physical Android device and a lower supported API. The configured minimum is Android API 24; target/compile is API 36.
- [ ] Check keyboard/navigation, app restore/relaunch, sign-in and sign-out, file import/export, offline/error states, and any platform-specific feature. Record results under `Tests` before submission.

## Build and verify

1. For local installation only: `pwsh -File Scripts\Build-The-Social-Base.ps1 -Task assembleDebug`.
2. For store delivery, create the key once with `pwsh -File Scripts\New-AndroidSigningKey.ps1 -AppName The-Social-Base -Alias upload -GenerateProtectedPassword`.
3. Build a signed APK for manual/APK store routes with `-Task assembleRelease`; build a signed AAB for Google Play with `-Task bundleRelease`.
4. Confirm the manifest, build type, version code/name, signing certificate fingerprint, and SHA-256 in the adjacent `.manifest.json` and `Transport\Database\releases.sqlite3`.
5. Stage only the signed release artifact with `Scripts\Stage-AndroidRelease.ps1`. Staging rejects debug builds.

## Store checklist

- [ ] Google Play: complete developer account verification, create the app listing, complete disclosures and Play App Signing enrollment, and make the first upload in Play Console. The Publishing API automation is for an existing app with an uploaded APK; it cannot create the first listing or complete required legal/policy forms. Newer personal accounts may have the 12-tester/14-day closed-test gate.
- [ ] PhonePe Appstore: create/verify the developer account, provide identity/business documents requested by the portal, add listing graphics and privacy policy, upload the signed APK/AAB, and submit for review.
- [ ] Amazon: use only for Fire devices. The Android mobile-device appstore was discontinued in 2025.
- [ ] APKPure: use its verified developer intake; the factory only stages the signed APK and checksum because no public upload API is verified here.
- [ ] F-Droid: only proceed after making the source public under a qualifying FOSS license, checking every dependency/resource license, and preparing F-Droid build metadata. F-Droid builds and reviews source; it is not a binary APK upload form.
- [ ] Save each submission receipt, review result, store track, and live listing URL in the release ledger.
