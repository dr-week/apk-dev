param(
    [ValidateSet('assembleDebug', 'assembleRelease', 'bundleRelease')]
    [string]$Task = 'assembleDebug',
    [string]$ProjectPath = 'C:\CODES\001\UNFOLLOWER',
    [ValidateRange(0, 2100000000)][int]$VersionCode = 0
)
$ErrorActionPreference = 'Stop'
$factory = Split-Path $PSScriptRoot -Parent
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$package = Get-Content (Join-Path $project 'package.json') -Raw | ConvertFrom-Json
$capacitor = Get-Content (Join-Path $project 'capacitor.config.ts') -Raw
$appId = [regex]::Match($capacitor, "appId:\s*'([^']+)'").Groups[1].Value
if (-not $appId) { throw 'Could not find Capacitor appId.' }
$env:ANDROID_VERSION_NAME = [string]$package.version
$versionScript = Join-Path $PSScriptRoot 'Get-NextVersionCode.ps1'
$env:ANDROID_VERSION_CODE = if ($VersionCode -gt 0) { [string]$VersionCode } else { [string](& $versionScript -PackageName $appId) }
$env:ANDROID_HOME = Join-Path $factory 'Android-SDK'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:ANDROID_AVD_HOME = Join-Path $factory 'Android-AVD'
$env:ANDROID_USER_HOME = Join-Path $factory 'Android-CLI'
$env:TEMP = Join-Path $factory 'Temp'
$env:TMP = $env:TEMP
$jdk = 'C:\Software\Java\Temurin-21\jdk-21.0.12.1+1'
if (-not (Test-Path (Join-Path $jdk 'bin\java.exe'))) { throw "JDK 21 missing: $jdk" }
$env:JAVA_HOME = $jdk
$env:PATH = "$jdk\bin;$(Join-Path $env:ANDROID_HOME 'platform-tools');$env:PATH"
"sdk.dir=$($env:ANDROID_HOME -replace '\\', '/')" | Set-Content -LiteralPath (Join-Path $project 'android\local.properties') -Encoding ascii
$signedRelease = $Task -in @('assembleRelease', 'bundleRelease')
if ($signedRelease) {
    $keyStore = Join-Path $factory 'Secrets\The-Social-Base\The-Social-Base-upload.p12'
    if (-not (Test-Path $keyStore)) {
        throw "App signing key missing. Create it once with Scripts\New-AndroidSigningKey.ps1 -AppName The-Social-Base -GenerateProtectedPassword."
    }
    $passwordFile = Join-Path $factory 'Secrets\The-Social-Base\upload-key-password.dpapi'
    if (Test-Path $passwordFile) {
        $protectedPassword = [IO.File]::ReadAllText($passwordFile).Trim()
        $secret = ConvertTo-SecureString -String $protectedPassword
    } else {
        $secret = Read-Host 'Enter the The Social Base upload-key password' -AsSecureString
    }
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret)
    try { $password = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
    $env:ANDROID_UPLOAD_KEYSTORE = $keyStore
    $env:ANDROID_UPLOAD_STORE_PASSWORD = $password
    $env:ANDROID_UPLOAD_KEY_ALIAS = 'upload'
    $env:ANDROID_UPLOAD_KEY_PASSWORD = $password
}

Push-Location $project
try {
    Write-Host "Building $($package.name) v$env:ANDROID_VERSION_NAME (Android code $env:ANDROID_VERSION_CODE; $Task)."
    npm run android:sync
    if ($LASTEXITCODE -ne 0) { throw 'Web build or Capacitor Android sync failed.' }
    & (Join-Path $PSScriptRoot 'Build-AndroidApp.ps1') -Name 'The-Social-Base' -Task $Task
    if ($LASTEXITCODE -ne 0) { throw "APK factory build failed: $Task" }
} finally {
    Pop-Location
    if ($signedRelease) {
        Remove-Item Env:ANDROID_UPLOAD_STORE_PASSWORD,Env:ANDROID_UPLOAD_KEY_PASSWORD -ErrorAction SilentlyContinue
        $password = $null
    }
}
