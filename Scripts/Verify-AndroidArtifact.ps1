param([Parameter(Mandatory)][string]$ArtifactPath)
$ErrorActionPreference = 'Stop'
$artifact = (Resolve-Path -LiteralPath $ArtifactPath).Path
$root = Split-Path $PSScriptRoot -Parent
$env:JAVA_HOME = 'C:\Software\Java\Temurin-21\jdk-21.0.12.1+1'
$env:PATH = (Join-Path $env:JAVA_HOME 'bin') + ';' + $env:PATH
$extension = [IO.Path]::GetExtension($artifact).ToLowerInvariant()
if ($extension -eq '.apk') {
    $signer = Get-ChildItem (Join-Path $root 'Android-SDK\build-tools') -Filter apksigner.bat -Recurse -File |
        Sort-Object FullName -Descending | Select-Object -First 1
    if (-not $signer) { throw 'Android apksigner is not installed.' }
    $details = & $signer.FullName verify --verbose --print-certs $artifact 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed.' }
    $fingerprint = [regex]::Match(($details -join "`n"), 'certificate SHA-256 digest:\s*([0-9a-fA-F]+)').Groups[1].Value
    $tool = 'apksigner'
} elseif ($extension -eq '.aab') {
    $jdk = 'C:\Software\Java\Temurin-21\jdk-21.0.12.1+1'
    $jarsigner = Join-Path $jdk 'bin\jarsigner.exe'
    if (-not (Test-Path $jarsigner)) { throw 'JDK jarsigner is not installed.' }
    & $jarsigner -verify $artifact
    if ($LASTEXITCODE -ne 0) { throw 'AAB signature verification failed.' }
    $keytool = Join-Path $jdk 'bin\keytool.exe'
    $details = & $keytool -printcert -jarfile $artifact 2>&1
    $fingerprint = [regex]::Match(($details -join "`n"), '(?im)^\s*SHA256:\s*([0-9a-fA-F:]+)').Groups[1].Value -replace ':', ''
    $tool = 'jarsigner'
} else { throw "Unsupported artifact type: $extension" }
if (-not $fingerprint) { throw 'Signature is valid but its SHA-256 signing certificate could not be read.' }
Write-Host "Signature verified: $artifact"
[pscustomobject]@{ tool = $tool; certificateSha256 = $fingerprint.ToLowerInvariant() }
