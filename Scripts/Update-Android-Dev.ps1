param([switch]$IncludeDownloadsInCleanup)
$ErrorActionPreference = 'Stop'
$update = Join-Path $PSScriptRoot 'Update-Android-Toolchain.ps1'
$cleanup = Join-Path $PSScriptRoot 'Clean-AndroidTemp.ps1'
& $update
if ($LASTEXITCODE -ne 0) { throw 'Android SDK and Bundletool update failed; cleanup was skipped.' }
if ($IncludeDownloadsInCleanup) { & $cleanup -IncludeDownloads }
else { & $cleanup }
Write-Host 'Android development tools are up to date; disposable temporary files were cleaned.'
