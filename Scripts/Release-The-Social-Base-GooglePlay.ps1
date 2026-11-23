param(
    [ValidateSet('internal', 'alpha', 'beta', 'production')]
    [string]$Track = 'internal',
    [string]$ReleaseNotes = 'The Social Base Android release',
    [switch]$Publish,
    [switch]$ConfirmProduction
)
$ErrorActionPreference = 'Stop'
if ($Track -eq 'production' -and $Publish -and -not $ConfirmProduction) {
    throw 'Production upload requires -ConfirmProduction.'
}
$root = Split-Path $PSScriptRoot -Parent
& (Join-Path $PSScriptRoot 'Build-The-Social-Base.ps1') -Task bundleRelease
$manifest = Get-ChildItem (Join-Path $root 'Factory\Development\The-Social-Base') -Filter '*.aab.manifest.json' -File |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $manifest) { throw 'The build finished without an AAB manifest.' }
$artifact = $manifest.FullName -replace '\.manifest\.json$', ''
& (Join-Path $PSScriptRoot 'Stage-AndroidRelease.ps1') -ArtifactPath $artifact -Store google-play -Track $Track
$queuedManifest = Get-ChildItem (Join-Path $root "Transport\Queue\google-play\$Track") -Filter '*.aab.manifest.json' -File |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $queuedManifest) { throw 'AAB staging did not create a queued manifest.' }
$queuedArtifact = $queuedManifest.FullName -replace '\.manifest\.json$', ''
$arguments = @{
    ArtifactPath = $queuedArtifact
    Track = $Track
    ReleaseNotes = $ReleaseNotes
}
if ($Publish) { $arguments.Publish = $true }
if ($ConfirmProduction) { $arguments.ConfirmProduction = $true }
& (Join-Path $PSScriptRoot 'Publish-GooglePlay.ps1') @arguments
