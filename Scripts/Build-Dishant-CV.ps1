param(
    [ValidateSet('assembleDebug', 'assembleRelease', 'bundleRelease')][string]$Task = 'assembleDebug',
    [ValidateSet('google-play', 'amazon', 'apkpure', 'indus', 'manual')][string]$StageForStore,
    [ValidateSet('internal', 'alpha', 'beta', 'production')][string]$Track = 'internal',
    [switch]$Publish
)
$ErrorActionPreference = 'Stop'
$factory = Split-Path $PSScriptRoot -Parent
$project = 'C:\CODES\DISHANTcv'
$jdk = 'C:\Software\Java\Temurin-21\jdk-21.0.12.1+1'
$env:JAVA_HOME = $jdk
$env:ANDROID_HOME = Join-Path $factory 'Android-SDK'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:ANDROID_USER_HOME = Join-Path $factory 'Android-CLI'
$env:ANDROID_AVD_HOME = Join-Path $factory 'Android-AVD'
$env:TEMP = Join-Path $factory 'Temp'
$env:TMP = $env:TEMP
New-Item -ItemType Directory -Force -Path $env:TEMP | Out-Null
if (-not (Test-Path (Join-Path $jdk 'bin\java.exe'))) { throw "JDK missing: $jdk" }
$version = (Get-Content (Join-Path $project 'package.json') -Raw | ConvertFrom-Json).version
$code = [int](& (Join-Path $PSScriptRoot 'Get-NextVersionCode.ps1') -PackageName 'com.dishant.cvstudio')
if ($LASTEXITCODE -ne 0) { throw 'Could not allocate Android version code.' }

$signed = $Task -in @('assembleRelease', 'bundleRelease')
if ($signed) {
    $key = Join-Path $factory 'Secrets\Dishant-CV\Dishant-CV-upload.p12'
    if (-not (Test-Path $key)) { throw "Create the app upload key first: Scripts\New-AndroidSigningKey.ps1 -AppName Dishant-CV" }
    $secret = Read-Host 'Upload-key password' -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret)
    try { $password = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
    $env:ANDROID_UPLOAD_KEYSTORE = $key
    $env:ANDROID_UPLOAD_STORE_PASSWORD = $password
    $env:ANDROID_UPLOAD_KEY_ALIAS = 'upload'
    $env:ANDROID_UPLOAD_KEY_PASSWORD = $password
}

try {
    Push-Location $project
    npm run build
    if ($LASTEXITCODE -ne 0) { throw 'Vite build failed.' }
    & (Join-Path $PSScriptRoot 'Build-AndroidApp.ps1') -Name 'Dishant-CV' -Task $Task -VersionCode $code -VersionName $version
    if ($LASTEXITCODE -ne 0) { throw "Android build failed: $Task" }
} finally {
    if ((Get-Location).Path -eq $project) { Pop-Location }
    Remove-Item Env:ANDROID_UPLOAD_KEYSTORE,Env:ANDROID_UPLOAD_STORE_PASSWORD,Env:ANDROID_UPLOAD_KEY_ALIAS,Env:ANDROID_UPLOAD_KEY_PASSWORD -ErrorAction SilentlyContinue
    Remove-Variable password -ErrorAction SilentlyContinue
}

$artifact = Get-ChildItem (Join-Path $factory 'Factory\Development\Dishant-CV') -Filter "*-code$code-*" -File |
    Where-Object Extension -in @('.apk', '.aab') | Select-Object -First 1
if (-not $artifact) { throw 'Build completed without a staged artifact.' }
if ($StageForStore) {
    $stageArgs = @{ ArtifactPath = $artifact.FullName; Store = $StageForStore }
    if ($StageForStore -eq 'google-play') { $stageArgs.Track = $Track }
    & (Join-Path $PSScriptRoot 'Stage-AndroidRelease.ps1') @stageArgs
}
if ($Publish) {
    if ($StageForStore -ne 'google-play' -or $Task -ne 'bundleRelease') { throw 'Automated upload requires bundleRelease and -StageForStore google-play.' }
    $trackFolder = Join-Path $factory ("Transport\Queue\google-play\$Track")
    $queued = Get-ChildItem $trackFolder -Filter "*-code$code-*.aab" -File | Select-Object -First 1
    if (-not $queued) { throw 'Queued Play AAB not found.' }
    & (Join-Path $PSScriptRoot 'Publish-GooglePlay.ps1') -ArtifactPath $queued.FullName -Track $Track -Publish
}
Write-Host "Ready: $($artifact.FullName)"
