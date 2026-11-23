# Secret material

Keep Google Play service-account JSON here at `google-play-service-account.json`.
Create app-specific upload keys using `Scripts\New-AndroidSigningKey.ps1`; these
are stored in `Secrets\<app-name>`. Restrict folder access to the publishing user.
Never commit keys, paste passwords into command history, or attach secrets to
release records. Keytool prompts for the key password; do not put it in a
command or script. Back up the key and recovery instructions securely, offline,
before the first public release.
