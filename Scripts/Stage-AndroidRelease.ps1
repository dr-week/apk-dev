param(
    [Parameter(Mandatory)][string]$ArtifactPath,
    [Parameter(Mandatory)][ValidateSet('google-play', 'amazon', 'apkpure', 'indus', 'manual')][string]$Store,
    [ValidateSet('internal', 'alpha', 'beta', 'production')][string]$Track = 'internal'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$artifact = (Resolve-Path -LiteralPath $ArtifactPath).Path
$manifestPath = "$artifact.manifest.json"
if (-not (Test-Path $manifestPath)) { throw "Build manifest missing: $manifestPath" }
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
if ($manifest.buildType -ne 'release') { throw 'Store queues accept release builds only; debug builds are for installation checks.' }
if ($manifest.buildType -ne 'release') { throw 'Debug builds cannot be staged for store delivery.' }
$hash = (Get-FileHash $artifact -Algorithm SHA256).Hash.ToLowerInvariant()
if ($hash -ne $manifest.sha256.ToLowerInvariant()) { throw 'Artifact checksum mismatch.' }
$signature = & (Join-Path $PSScriptRoot 'Verify-AndroidArtifact.ps1') -ArtifactPath $artifact
if ($manifest.signingCertificateSha256 -and
    $signature.certificateSha256 -ne $manifest.signingCertificateSha256) {
    throw 'Artifact signing certificate does not match the build manifest.'
}
$extension = [IO.Path]::GetExtension($artifact).ToLowerInvariant()
if ($Store -eq 'google-play' -and $extension -ne '.aab') { throw 'Google Play requires a signed AAB.' }
if ($Store -in @('apkpure', 'manual') -and $extension -ne '.apk') { throw "$Store delivery expects an APK." }
if ($Store -eq 'indus' -and $extension -notin @('.apk', '.aab')) { throw 'Indus accepts APK or AAB.' }
if ($Store -eq 'google-play' -and -not (Test-Path (Join-Path $root 'Secrets\google-play-service-account.json'))) {
    Write-Warning 'Play upload credentials are not configured; this command only stages a queue copy.'
}
$trackFolder = if ($Store -eq 'google-play') { $Track } else { 'default' }
$folder = Join-Path $root "Transport\Queue\$Store\$trackFolder\$($manifest.packageName)-v$($manifest.versionName)-code$($manifest.versionCode)-$($manifest.artifactType)"
if (Test-Path $folder) {
    $existingManifest = Join-Path $folder ((Split-Path $artifact -Leaf) + '.manifest.json')
    if (Test-Path $existingManifest) {
        $queued = Get-Content $existingManifest -Raw | ConvertFrom-Json
        if ($queued.sha256 -ne $hash) { throw "A different release already occupies this queue path: $folder" }
        if ($queued.status -eq 'queued') { Write-Host "Already staged for ${Store}: $folder"; return }
        throw "This release is already marked '$($queued.status)' in the queue: $folder"
    }
} else { New-Item -ItemType Directory -Path $folder -Force | Out-Null }
$copy = Join-Path $folder (Split-Path $artifact -Leaf)
if (Test-Path $copy) {
    if ((Get-FileHash $copy -Algorithm SHA256).Hash.ToLowerInvariant() -ne $hash) {
        throw "An unrelated file already occupies the queue path: $copy"
    }
} else { Copy-Item -LiteralPath $artifact -Destination $copy }
Set-Content "$copy.sha256" "$hash  $(Split-Path $copy -Leaf)" -Encoding ascii
$manifest.artifactPath = $copy
$manifest.sha256 = $hash
$manifest.stage = 'queued'
$manifest.status = 'queued'
$manifest | Add-Member -NotePropertyName store -NotePropertyValue $Store -Force
$manifest | Add-Member -NotePropertyName track -NotePropertyValue $(if ($Store -eq 'google-play') { $Track } else { $null }) -Force
$manifest | Add-Member -NotePropertyName queuedAt -NotePropertyValue ([DateTime]::UtcNow.ToString('o')) -Force
$queuedManifest = "$copy.manifest.json"
$manifest | ConvertTo-Json | Set-Content $queuedManifest -Encoding utf8
& python (Join-Path $PSScriptRoot 'release_registry.py') --database (Join-Path $root 'Transport\Database\releases.sqlite3') register --manifest $queuedManifest
if ($LASTEXITCODE -ne 0) { throw 'Release queued but registry update failed.' }
Write-Host "Staged for ${Store}: $copy"
