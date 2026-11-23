param([switch]$IncludeDownloads)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$targets = @((Join-Path $root 'Temp'), (Join-Path $root 'Android-SDK\.temp'),
    (Join-Path $root 'Scripts\__pycache__'))
if ($IncludeDownloads) { $targets += Join-Path $root 'Cache\Downloads' }
foreach ($path in $targets) {
    if (-not (Test-Path -LiteralPath $path)) { continue }
    $resolved = (Resolve-Path -LiteralPath $path).Path
    if (-not $resolved.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing cleanup outside factory root: $resolved"
    }
    Get-ChildItem -LiteralPath $resolved -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne 'README.md' } |
        Remove-Item -Force -Recurse -ErrorAction Stop
}
$toolsArchive = Join-Path $root 'Android-SDK\cmdline-tools\tools.zip'
$installedManager = Join-Path $root 'Android-SDK\cmdline-tools\latest\bin\sdkmanager.bat'
if ((Test-Path $toolsArchive) -and (Test-Path $installedManager)) {
    Remove-Item -LiteralPath $toolsArchive -Force
    Write-Host 'Removed extracted Android command-line tools archive.'
}
Write-Host 'Removed disposable temporary files. Installed SDKs, AVDs, secrets, and release artifacts were not touched.'
