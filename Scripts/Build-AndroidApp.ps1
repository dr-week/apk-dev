param(
    [Parameter(Mandatory)][string]$Name,
    [ValidatePattern('^(assemble|bundle)[A-Za-z0-9]*(Release|Debug)$')][string]$Task = 'assembleRelease',
    [ValidateRange(1,2100000000)][int]$VersionCode = 0,
    [string]$VersionName
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$jdk = 'C:\Software\Java\Temurin-21\jdk-21.0.12.1+1'
$env:JAVA_HOME = $jdk
$env:ANDROID_HOME = Join-Path $root 'Android-SDK'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:ANDROID_USER_HOME = Join-Path $root 'Android-CLI'
$registry = Get-Content (Join-Path $root 'Apps\registry.json') -Raw | ConvertFrom-Json
$app = $registry.apps | Where-Object { $_.name -eq $Name } | Select-Object -First 1
if (-not $app) { throw "App is not registered: $Name" }
$project = (Resolve-Path $app.projectPath).Path
$wrapper = Join-Path $project 'gradlew.bat'
if (-not (Test-Path $wrapper)) { $wrapper = Join-Path $project 'android\gradlew.bat' }
$androidProject = if (Test-Path $wrapper) { Split-Path $wrapper -Parent } else { Join-Path $project 'android' }
if (-not (Test-Path (Join-Path $androidProject 'settings.gradle')) -and -not (Test-Path (Join-Path $androidProject 'settings.gradle.kts'))) {
    throw "Gradle wrapper or Android Gradle project missing: $project"
}
$wrapperProperties = Join-Path $androidProject 'gradle\wrapper\gradle-wrapper.properties'
$wrapperVersion = if (Test-Path $wrapperProperties) {
    [regex]::Match((Get-Content $wrapperProperties -Raw), 'gradle-(\d+\.\d+(?:\.\d+)?)-').Groups[1].Value
}
$installedGradle = if ($wrapperVersion) { Join-Path $root "Gradle\$wrapperVersion\bin\gradle.bat" }
if (-not $installedGradle -or -not (Test-Path $installedGradle)) {
    $installedGradle = Get-ChildItem (Join-Path $root 'Gradle') -Directory | Sort-Object { [version]$_.Name } -Descending |
        ForEach-Object { Join-Path $_.FullName 'bin\gradle.bat' } | Where-Object { Test-Path $_ } | Select-Object -First 1
}
$gradleCommand = if ($wrapperVersion -and (Test-Path (Join-Path $root "Gradle\$wrapperVersion\bin\gradle.bat"))) { Join-Path $root "Gradle\$wrapperVersion\bin\gradle.bat" }
    elseif (Test-Path $wrapper) { $wrapper }
    elseif ($installedGradle) { $installedGradle }
    else { throw 'No Gradle wrapper or installed Gradle distribution is available.' }
$logRoot = Join-Path $root 'Logs\Builds'
New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
$buildLog = Join-Path $logRoot "$Name-$Task-$(Get-Date -Format yyyyMMdd-HHmmss).log"
Start-Transcript -Path $buildLog | Out-Null
Push-Location $androidProject
try {
    $gradleArgs = @($Task)
    if ($VersionCode -gt 0) { $gradleArgs += "-PappVersionCode=$VersionCode" }
    if ($VersionName) { $gradleArgs += "-PappVersionName=$VersionName" }
    & $gradleCommand @gradleArgs
    if ($LASTEXITCODE -ne 0) { throw "Gradle failed: $Task ($LASTEXITCODE)" }
}
finally { Pop-Location; Stop-Transcript | Out-Null }
$ext = if ($Task.StartsWith('bundle')) { '*.aab' } else { '*.apk' }
$buildType = if ($Task.EndsWith('Release')) { 'release' } else { 'debug' }
$outputs = Join-Path $androidProject 'app\build\outputs'
$artifact = Get-ChildItem $outputs -Filter $ext -File -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $artifact) { throw "No $ext output under $outputs" }
$manifestXml = & (Join-Path $PSScriptRoot 'Read-AndroidArtifactManifest.ps1') -ArtifactPath $artifact.FullName
$packageName = $manifestXml.packageName
$versionName = $manifestXml.versionName
$versionCode = $manifestXml.versionCode
if (-not $packageName -or -not $versionName -or -not $versionCode) {
    throw 'Could not read package/version from build output.'
}
$verify = Join-Path $PSScriptRoot 'Verify-AndroidArtifact.ps1'
$signature = & $verify -ArtifactPath $artifact.FullName
$destination = Join-Path $root "Factory\Development\$Name"
New-Item -ItemType Directory -Path $destination -Force | Out-Null
$label = if ($app.displayName) { $app.displayName -replace '[^A-Za-z0-9.-]+', '-' } else { $Name }
$file = Join-Path $destination ("$label-v$versionName-code$versionCode-$buildType" + $artifact.Extension)
if (Test-Path $file) {
    $existingHash = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
    $sourceHash = (Get-FileHash -LiteralPath $artifact.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($existingHash -ne $sourceHash) { throw "Refusing to overwrite a different artifact: $file" }
} else { Copy-Item -LiteralPath $artifact.FullName -Destination $file }
$hash = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
$manifest = [ordered]@{ app = $Name; displayName = $app.displayName; packageName = $packageName; versionName = $versionName; versionCode = [int]$versionCode; buildTask = $Task; buildType = $buildType; buildLogPath = $buildLog; artifactType = $artifact.Extension.TrimStart('.'); artifactPath = $file; sha256 = $hash; signingTool = $signature.tool; signingCertificateSha256 = $signature.certificateSha256; stage = 'development'; status = 'built'; createdAt = [DateTime]::UtcNow.ToString('o') }
$manifest | ConvertTo-Json | Set-Content -LiteralPath "$file.manifest.json" -Encoding utf8
& python (Join-Path $PSScriptRoot 'release_registry.py') --database (Join-Path $root 'Transport\Database\releases.sqlite3') register --manifest "$file.manifest.json"
if ($LASTEXITCODE -ne 0) { throw 'Artifact built but SQLite registration failed.' }
Write-Host "Built $packageName v$versionName ($versionCode, $buildType): $file"
