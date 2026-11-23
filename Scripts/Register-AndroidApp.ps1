param(
    [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]*$')][string]$Name,
    [Parameter(Mandatory)][string]$ProjectPath,
    [string]$DisplayName = $Name
)
$ErrorActionPreference = 'Stop'
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$wrappers = @((Join-Path $project 'gradlew.bat'), (Join-Path $project 'android\gradlew.bat'))
if (-not ($wrappers | Where-Object { Test-Path -LiteralPath $_ })) {
    throw "No Gradle wrapper at project root or android subfolder: $project"
}
$registry = Join-Path $PSScriptRoot '..\Apps\registry.json'
$data = Get-Content -LiteralPath $registry -Raw | ConvertFrom-Json
$existing = @($data.apps | Where-Object { $_.name -eq $Name })
if ($existing) { throw "App key already registered: $Name" }
$data.apps += [pscustomobject]@{ name = $Name; displayName = $DisplayName; projectPath = $project }
$data | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $registry -Encoding utf8
Write-Host "Registered $Name -> $project"
