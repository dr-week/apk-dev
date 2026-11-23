# APK-DEV Control Center

Local-first release dashboard built on the user's [Zuari framework](https://github.com/dr-week/fast-framework) checkout at `C:\CODES\webframework\fast` (signals + direct DOM templates + glyphs), Vite, TypeScript, and SCSS. No React or JSX. UI source is modular; keep every authored TS and SCSS file at or below 150 lines.

## Run

```powershell
cd C:\Software\APK-DEV\Control-Center
pnpm install
pnpm dev
```

The Vite aliases resolve Zuari package sources directly from the framework checkout. Keep that checkout available at the configured path. `pnpm build` creates the static production UI in `dist/`.

## Current scope

Phase 1 reads app names and paths from `Apps/registry.json`, with package/version/status metadata cross-checked against current project manifests and the release ledger. It supports app search, status filter, name/date/version/status sorting, grid/list switching, and provider capability overview. Store connections are intentionally disabled. This UI does not yet read or mutate the SQLite release ledger, access credentials, build packages, or publish. Use existing `Scripts/` commands for build/stage operations until their typed, validated bridge is implemented.

## Security boundary

Never put store passwords, OAuth tokens, signing keys, or service-account JSON in renderer code, local storage, registry JSON, logs, or SQLite. Dashboard Google login and Play publishing authorization are separate. Publishing requires a protected main-process/credential-vault bridge and explicit artifact/account/store confirmation. See [the architecture spec](../Docs/STORE_CONTROL_CENTER_SPEC.md).
