param(
    [Parameter(Mandatory)][string]$ArtifactPath,
    [ValidateSet('internal', 'alpha', 'beta', 'production')][string]$Track = 'internal',
    [ValidateSet('draft', 'inProgress', 'completed')][string]$ReleaseStatus = 'draft',
    [string]$ReleaseNotes = 'Android release',
    [ValidateRange(0.01, 0.99)][double]$UserFraction = 0.1,
    [string]$CredentialsPath = 'C:\Software\APK-DEV\Secrets\google-play-service-account.json',
    [switch]$Publish,
    [switch]$ConfirmProduction
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$artifact = (Resolve-Path -LiteralPath $ArtifactPath).Path
$manifestPath = "$artifact.manifest.json"
if (-not (Test-Path $manifestPath)) { throw 'Release manifest is missing.' }
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
if ($manifest.store -ne 'google-play' -or $manifest.stage -ne 'queued') { throw 'Stage this AAB for google-play first.' }
if ($manifest.buildType -ne 'release') { throw 'Google Play requires a release-signed AAB.' }
if ($manifest.track -ne $Track) { throw "Artifact is queued for '$($manifest.track)'; requested track is '$Track'. Stage it again for that track." }
if ([IO.Path]::GetExtension($artifact) -ne '.aab') { throw 'Google Play upload requires an AAB.' }
if ((Get-FileHash $artifact -Algorithm SHA256).Hash.ToLowerInvariant() -ne $manifest.sha256.ToLowerInvariant()) { throw 'AAB SHA-256 mismatch.' }
if ($Track -eq 'production' -and -not $ConfirmProduction) { throw 'Production requires -ConfirmProduction.' }
& (Join-Path $PSScriptRoot 'Verify-AndroidArtifact.ps1') -ArtifactPath $artifact
if (-not $Publish) {
    Write-Host "Dry run: ready to upload $artifact to Google Play $Track ($ReleaseStatus)."
    Write-Host 'No network changes made. Add -Publish to upload and commit.'
    return
}
if (-not (Test-Path $CredentialsPath)) { throw "Service-account credentials missing: $CredentialsPath" }
. (Join-Path $PSScriptRoot 'Get-PlayAccessToken.ps1')
$token = Get-PlayAccessToken $CredentialsPath
$headers = @{ Authorization = "Bearer $token"; Accept = 'application/json' }
$base = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications'
$upload = 'https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications'
$package = [Uri]::EscapeDataString([string]$manifest.packageName)
$editId = $null
try {
    $edit = Invoke-RestMethod -Method Post -Uri "$base/$package/edits" -Headers $headers -ContentType 'application/json' -Body '{}'
    $editId = [Uri]::EscapeDataString([string]$edit.id)
    $bundle = Invoke-RestMethod -Method Post -Uri "$upload/$package/edits/$editId/bundles?uploadType=media" -Headers $headers -ContentType 'application/octet-stream' -InFile $artifact -TimeoutSec 600
    if ([int64]$bundle.versionCode -ne [int64]$manifest.versionCode) { throw 'Play received a different version code.' }
    $release = @{ name = "$($manifest.versionName) (code $($manifest.versionCode))"; versionCodes = @([string]$manifest.versionCode); status = $ReleaseStatus; releaseNotes = @(@{ language = 'en-US'; text = $ReleaseNotes }) }
    if ($ReleaseStatus -eq 'inProgress') { $release.userFraction = $UserFraction }
    $body = @{ track = $Track; releases = @($release) } | ConvertTo-Json -Depth 8
    Invoke-RestMethod -Method Put -Uri "$base/$package/edits/$editId/tracks/$Track" -Headers $headers -ContentType 'application/json' -Body $body | Out-Null
    Invoke-RestMethod -Method Post -Uri "${base}/${package}/edits/${editId}:commit?changesInReviewBehavior=ERROR_IF_IN_REVIEW" -Headers $headers -ContentType 'application/json' -Body '' | Out-Null
} catch {
    if ($editId) { try { Invoke-RestMethod -Method Delete -Uri "$base/$package/edits/$editId" -Headers $headers | Out-Null } catch { Write-Warning 'Could not delete failed Play edit; inspect Play Console before retry.' } }
    throw
}
$manifest.status = 'uploaded'
$manifest.receipt = $edit.id
$manifest.uploadedAt = [DateTime]::UtcNow.ToString('o')
$manifest | ConvertTo-Json | Set-Content $manifestPath -Encoding utf8
& python (Join-Path $PSScriptRoot 'release_registry.py') --database (Join-Path $root 'Transport\Database\releases.sqlite3') mark --package $manifest.packageName --version-code $manifest.versionCode --store google-play --track $Track --status uploaded --receipt $edit.id
if ($LASTEXITCODE -ne 0) { throw 'Play upload succeeded but local status update failed.' }
Write-Host "Uploaded $($manifest.packageName) v$($manifest.versionName) to Google Play $Track."
