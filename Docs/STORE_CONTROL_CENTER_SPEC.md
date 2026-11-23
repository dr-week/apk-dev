# Store Control Center — Architecture and Delivery Plan

## Purpose

One reusable release desk for every registered app. Existing Android SDK, `Scripts/`, `Apps/registry.json`, `Factory/`, and `Transport/Database/releases.sqlite3` remain the build and release source of truth. The UI reads and orchestrates those tools; it does not replace per-app factories.

## Product workflow

`Register app → inspect project → allocate version → build → sign → verify → stage → choose store/account → review → upload or portal handoff → track receipt`

The dashboard must never report a release as published merely because a file was staged or accepted for upload. Every upload requires a review displaying app, package, artifact, checksum, version, store, account, track, and action. Default is dry-run. Production submission needs a second explicit confirmation.

## Reuse and repository boundaries

| Existing area | Responsibility |
| --- | --- |
| `Apps/registry.json` | Registered source projects and display labels |
| `Scripts/` | Android toolchain, build, validation, signing, staging, store CLI operations |
| `Factory/` | Development artifacts and app-specific build output |
| `Transport/Queue/` | Artifacts prepared for distribution |
| `Transport/Stores/` | Provider handoff and receipts |
| `Transport/Database/releases.sqlite3` | Existing release ledger; extend with versioned migrations |
| `Secrets/` | Existing protected signing material; never expose to UI or check into source control |
| `Control-Center/` | Desktop UI and TypeScript orchestration only |

Do not move an installed SDK, emulator image, signing identity, or active ledger as part of UI work. Keep disposable downloads and unpacked temporary files in `Cache/Downloads/` and `Temp/`, then clean only known transient files after successful extraction/build.

## Application architecture

Frontend: the requested Zuari framework (`@zuari/signals`, `@zuari/dom`, and `@zuari/glyphs`) with Vite, TypeScript, and SCSS. UI uses direct DOM templates and fine-grained signals; no React, JSX, or Virtual DOM. Framework source is linked from `C:\CODES\webframework\fast`. Phase 1 is a local web UI and reads `Apps/registry.json` at build time. Filesystem, release-ledger, credentials, and build/publish operations require a separately secured local TypeScript service bridge before they are enabled. Store pages open with an explicit external-browser handoff. Secrets must ultimately use Windows Credential Manager or another OS-backed vault; only opaque secret references and non-sensitive metadata enter the database. No browser local storage, JSON registry, logs, database rows, or build manifests may contain secrets.

Layers: `app` shell/navigation; `features/apps`, `connections`, `builds`, `releases`, `assets`, `activity`, `settings`; `providers` adapter contracts and capability declarations; `shared/ui`, `shared/contracts`, `shared/services`; local service bridge; versioned database migrations. UI code depends on provider contracts, never vendor response shapes. Keep every authored TS/TSX/SCSS/config source module under 150 lines; split by responsibility. Generated files, lockfiles, and third-party sources are exempt.

## Data model and migration plan

Keep the existing release ledger and add additive, numbered migrations. Tables: `apps` (stable registry key, display name, package ID, source path, framework, category, tags, created/updated UTC); `store_connections` (provider, account label, type, status, scopes, secret reference, checked/revoked times); `app_store_links` (app, provider, connection, listing ID, track); `builds` (app, version name/code, variant, timestamps, artifact/manifest/log paths, SHA-256, signing fingerprint, result); `store_events` (app/build, provider, track, status, receipt, safe summary); `activity_events` (actor, action, target, timestamp, redacted detail); `release_calendar` (app, target date, store, status). Foreign keys, indexes on app/date/state, UTC ISO timestamps, transaction-backed migrations, integrity check, backup/restore with checksum. Keep passwords, refresh tokens, private keys, service-account JSON, and raw OAuth responses out of SQLite.

## Feature definition

- **Overview:** health and action-required counts, release readiness, latest builds, recent app and provider activity.
- **App library:** search name/package/path, filter state/category/store, sort by created/modified/built/published/name/version/status, grid/list, pagination, multi-select. Initial UI uses a compact list and three apps from the registry.
- **App workspace:** overview, builds/artifacts, releases, store links/accounts, listing assets, signing status, logs, audit history.
- **Connections:** multiple accounts per provider, account identity, scopes, status, last check, reconnect/revoke, app assignment. Dashboard identity is distinct from Play publishing permission.
- **Release desk:** preflight, version allocation, build, verify, sign, stage, draft/upload, store state, receipt and rollback metadata. Debug/unsigned, invalid signature, non-increasing version, unhealthy connection, or missing requirements block upload.
- **Assets, calendar, notifications, audit, health, backup:** shared metadata and file organization; no duplicate app-specific build systems.
- **Manual routes:** clearly label stores without verified publishing APIs as portal handoff; maintain an auditable pending state.

## Provider capability matrix

| Provider | Initial support | Constraints |
| --- | --- | --- |
| Google Play | API adapter after explicit account authorization; draft/internal track first | Dashboard sign-in does not grant publishing. Use OAuth/service account with Play Console access. Require store-compatible signed bundle and validate current target API policy. |
| Amazon Appstore | Portal for first submission; adapter for supported existing-app updates | Submission API documents APK updates; AAB is not accepted through that API. LWA/API credentials required. |
| F-Droid | Source and metadata submission preparation | Source/repository review and build policy; not a binary APK upload endpoint. |
| APKPure | Portal handoff | Enable an API only after current official access and upload contract are verified. |
| Indus/other stores | Portal handoff | Keep provider adapter disabled until official credentials, API terms, and tested contract are available. |

## Accounts and security

Never collect store website passwords. OAuth must use state/PKCE where supported, least scopes, system browser, validated redirect, explicit consent, and revocation. Google dashboard login is a separate identity connection from Play Developer API access. Amazon uses Login with Amazon only for documented API workflows. Service-account key files should be imported via file picker, validated, then protected by OS-backed encryption and removed from temporary staging. Logs redact tokens, email where not necessary, and credential payloads. Disconnected/expired accounts block publishing. Never claim upload support from an undocumented endpoint.

## UI direction

Use the supplied references as mood, not literal layouts: deep plum/ink canvas; warm amber/coral and lilac/violet ambient light; finely grained local texture; restrained frosted panels; soft edges and glass depth. Keep text/status on opaque-enough surfaces, status labels textual, focus visible, keyboard access complete, and reduced motion respected. Glow is reserved for focus and the primary action. App list defaults to readable compact rows; cards are used for overview. Responsive desktop-first layout supports collapsed navigation and narrow stacked views.

## Delivery phases and gates

1. **Foundation (current):** Zuari/Vite shell, design tokens, registry-backed app list, search/sort/filter, and store capability catalog. Publishing and connection actions are disabled. Build/ledger data bridge and registration workflow remain future phase work.
2. **Data and app workspace:** migration/adaptor for existing ledger, app registration, builds, release history, checksum/signature preflight, activity log.
3. **Credentials and connections:** OS vault, account health, explicit OAuth flows, reconnect/revoke; test without publishing.
4. **Publishing:** Google Play draft/internal upload first; Amazon supported update API next; portal handoff for other stores; F-Droid source preparation.
5. **Hardening:** backup/restore, accessibility, security review, API contract tests, installable desktop packaging, signed release.

Each phase must document inputs, outputs, limitations, and recovery steps. Tests are required for database migrations, version allocation, artifact validation, redaction, provider capability gating, and publish confirmation. UI must remain useful when no account is connected.

## Acceptance criteria

- Existing registry apps appear without manually duplicating the registry.
- Search, filters, date/name/version/status sort, and view switching work and are keyboard accessible.
- Provider readiness is never fabricated; unsupported methods route to documented manual handoff.
- No real publish can run without credentials, valid artifact preflight, a review, and explicit confirmation.
- Secrets never appear in UI logs, database rows, app registry, or source control.
- Each source module is at most 150 lines, TypeScript/TSX and SCSS only.
- Build, packaging, upload state, receipt, and rollback are traceable by app/version/checksum.

## Research references

- [Zuari framework source and documentation](https://github.com/dr-week/fast-framework)
- [Google Play API setup](https://developers.google.com/android-publisher/getting_started), [authorization](https://developers.google.com/android-publisher/authorization), [target API policy](https://developer.android.com/google/play/requirements/target-sdk)
- [Amazon Submission API overview](https://developer.amazon.com/docs/app-submission-api/overview.html), [authentication](https://developer.amazon.com/docs/app-submission-api/auth.html)
- [F-Droid submission](https://f-droid.org/docs/Submitting_to_F-Droid_Quick_Start_Guide/), [build policy](https://f-droid.org/docs/Building_Applications/)
- [Zuari GitHub repository](https://github.com/dr-week/fast-framework)
- [Android developer discussion on alternative stores](https://www.reddit.com/r/androiddev/comments/1me0m3j): anecdotal community input only; compatibility, distribution reach, and account onboarding vary by app and store.
