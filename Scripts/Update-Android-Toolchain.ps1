param()
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$cli = Join-Path $root 'Android-CLI\bin\android-cli.exe'
if (-not (Test-Path $cli)) { throw "Android CLI missing: $cli" }
$env:ANDROID_HOME = Join-Path $root 'Android-SDK'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:ANDROID_USER_HOME = Join-Path $root 'Android-CLI'
$env:TEMP = Join-Path $root 'Temp'
$env:TMP = $env:TEMP
New-Item -ItemType Directory -Path @($env:TEMP, (Join-Path $root 'Cache\Downloads'), (Join-Path $root 'Logs')) -Force | Out-Null
Start-Transcript -Path (Join-Path $root "Logs\toolchain-update-$(Get-Date -Format yyyyMMdd-HHmmss).log") | Out-Null
try {
& $cli --no-metrics "--sdk=$env:ANDROID_HOME" sdk update --no-downgrade
if ($LASTEXITCODE -ne 0) { throw "Android SDK update failed: $LASTEXITCODE" }
$version = '1.18.3'
$expected = 'a099cfa1543f55593bc2ed16a70a7c67fe54b1747bb7301f37fdfd6d91028e29'
$tools = Join-Path $root 'Tools'
$jar = Join-Path $tools "bundletool-all-$version.jar"
if (-not (Test-Path $jar)) {
    New-Item -ItemType Directory -Path $tools -Force | Out-Null
    $download = Join-Path $root "Cache\Downloads\bundletool-all-$version.jar"
    try {
        Invoke-WebRequest "https://github.com/google/bundletool/releases/download/$version/bundletool-all-$version.jar" -OutFile $download
        if ((Get-FileHash $download -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected) {
            throw 'Bundletool SHA-256 verification failed.'
        }
        Move-Item -LiteralPath $download -Destination $jar
    } finally {
        if (Test-Path $download) { Remove-Item -LiteralPath $download -Force }
    }
}
if ((Get-FileHash $jar -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected) { throw 'Installed Bundletool checksum is invalid.' }
Write-Host "Updated Android SDK and verified Bundletool $version. Gradle remains controlled by each app's wrapper."
} finally { Stop-Transcript | Out-Null }
