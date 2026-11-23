param()
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$jdk = 'C:\Software\Java\Temurin-21\jdk-21.0.12.1+1'
if (-not (Test-Path (Join-Path $jdk 'bin\java.exe'))) { throw "Install JDK 21 before Android tools: $jdk" }
$env:JAVA_HOME = $jdk
$env:ANDROID_HOME = Join-Path $root 'Android-SDK'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:ANDROID_USER_HOME = Join-Path $root 'Android-CLI'
$env:TEMP = Join-Path $root 'Temp'
$env:TMP = $env:TEMP
$cli = Join-Path $root 'Android-CLI\bin\android-cli.exe'
New-Item -ItemType Directory -Path @($env:TEMP, $env:ANDROID_HOME,
    $env:ANDROID_USER_HOME, (Join-Path $root 'Cache\Downloads'),
    (Join-Path $root 'Logs')) -Force | Out-Null
if (-not (Test-Path $cli)) {
    $installer = Join-Path $env:TEMP 'install-android-cli.cmd'
    try {
        Invoke-WebRequest 'https://dl.google.com/android/cli/latest/windows_x86_64/install.cmd' -OutFile $installer
        & $env:ComSpec /d /c "`"$installer`""
        if ($LASTEXITCODE -ne 0) { throw "Android CLI installer failed: $LASTEXITCODE" }
    } finally {
        if (Test-Path $installer) { Remove-Item -LiteralPath $installer -Force }
    }
}
if (-not (Test-Path $cli)) { throw "Android CLI missing after install: $cli" }
Start-Transcript -Path (Join-Path $root "Logs\toolchain-install-$(Get-Date -Format yyyyMMdd-HHmmss).log") | Out-Null
try {
    $packages = @('cmdline-tools/latest', 'platform-tools', 'emulator',
        'platforms/android-36', 'build-tools/36.0.0',
        'system-images/android-36/google_apis/x86_64')
    & $cli --no-metrics "--sdk=$env:ANDROID_HOME" sdk install @packages
    if ($LASTEXITCODE -ne 0) { throw "Android SDK install failed: $LASTEXITCODE" }
} finally { Stop-Transcript | Out-Null }
& (Join-Path $PSScriptRoot 'Update-Android-Toolchain.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Android toolchain update failed.' }
Write-Host 'Android CLI, SDK API 36, Build Tools, platform tools, emulator, and Bundletool are installed.'
