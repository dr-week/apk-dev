param(
    [Parameter(Mandatory)][string]$PackageName,
    [Parameter(Mandatory)][int]$VersionCode,
    [Parameter(Mandatory)][ValidateSet('google-play', 'amazon', 'apkpure', 'indus', 'manual')][string]$Store,
    [Parameter(Mandatory)][ValidateSet('uploaded', 'review', 'published', 'failed')][string]$Status,
    [ValidateSet('internal', 'alpha', 'beta', 'production')][string]$Track = 'internal',
    [string]$Receipt = ''
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$selectedTrack = if ($Store -eq 'google-play') { $Track } else { '' }
& python (Join-Path $PSScriptRoot 'release_registry.py') --database (Join-Path $root 'Transport\Database\releases.sqlite3') mark --package $PackageName --version-code $VersionCode --store $Store --track $selectedTrack --status $Status --receipt $Receipt
if ($LASTEXITCODE -ne 0) { throw 'Could not update release status.' }
