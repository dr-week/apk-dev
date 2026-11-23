# Tool and platform research

Research checked 9 November 2026. Prefer the Android SDK command-line tools, each app's Gradle wrapper, and Google's Bundletool over duplicating build tooling. This machine already has Android CLI, SDK Platform/Build Tools 36, emulator, API 36 image, and JDK 21. Bundletool is the official Google release; its pinned SHA-256 is sourced from Scoop's package manifest and checked by the updater. No Android Studio is needed for this command-line workflow.

Useful maintained projects:

- [Google Bundletool](https://github.com/google/bundletool): official AAB inspection and device APK generation; used here to read the manifest from AABs.
- [Fastlane](https://github.com/fastlane/fastlane): established mobile release automation, including Google Play `supply`; an optional alternative for multi-platform CI, not required for this Windows factory.
- [F-Droid fdroidserver](https://gitlab.com/fdroid/fdroidserver): official community tooling for source-built repository releases; F-Droid inclusion itself is a source/metadata review.
- [Gradle Wrapper](https://docs.gradle.org/current/userguide/gradle_wrapper.html): pins Gradle per app, preventing incompatible global upgrades.
- [Android SDK command-line tools](https://developer.android.com/tools): shared SDK package manager and build tools.

Google Play's official API supports edits, AAB upload, track updates, and commit. This factory provides an explicit `Publish-GooglePlay.ps1` adapter; it defaults to dry-run, requires a staged AAB and service-account access, and requires `-ConfirmProduction` for production. Amazon has an official API for APK updates to existing listings, but first submissions use the console and OAuth profile/app ID setup is required; this factory currently stages Amazon APKs for the console rather than making an unverified API call. APKPure and PhonePe Indus retain portal/manual paths until their current authenticated upload contracts and account access are confirmed. Never automate browser login or store approval steps with saved passwords.

Reddit developer reports are useful troubleshooting context but are not authoritative policy or API references; store rules and fees above are based on the linked official documentation. F-Droid's build requirements can exclude proprietary SDKs, so a Play build is not automatically eligible for F-Droid.

Community reports are consistent with staging on Play's internal track before wider rollout and using Fastlane when teams want a maintained wrapper instead of a bespoke API client ([r/androiddev thread](https://www.reddit.com/r/androiddev/comments/1xbqeso/have_anyone_used_fastlane_is_there_any_way_to/)). An F-Droid discussion also highlights the trade-off between reproducible builds and relying on F-Droid's signing/build pipeline ([r/fossdroid thread](https://www.reddit.com/r/fossdroid/comments/1v9qdze/do_people_prefer_reproducible_builds/)). Treat both as anecdotal; official API and inclusion documentation controls.
