param([string]$RepositoryRoot = $(if ($env:APK_DEV_REPO) { $env:APK_DEV_REPO } else { 'C:\CODES\money\mm' }), [Parameter(ValueFromRemainingArguments = $true)][string[]]$ScriptArgs)
$ErrorActionPreference = 'Stop'
$script = Join-Path $RepositoryRoot 'scripts\release\package-android-release.ps1'
if (-not (Test-Path $script)) { throw "Repository helper not found: $script" }
& $script @ScriptArgs
exit $LASTEXITCODE
