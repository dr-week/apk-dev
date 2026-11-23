$root = Split-Path $PSScriptRoot -Parent
$jdk = 'C:\Software\Java\Temurin-21\jdk-21.0.12.1+1'
if (-not (Test-Path (Join-Path $jdk 'bin\java.exe'))) { throw "JDK 21 missing: $jdk" }
$env:JAVA_HOME = $jdk
$env:ANDROID_HOME = Join-Path $root 'Android-SDK'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:ANDROID_AVD_HOME = Join-Path $root 'Android-AVD'
$env:ANDROID_USER_HOME = Join-Path $root 'Android-CLI'
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$pathEntries = @($userPath -split ';' | Where-Object { $_ })
$additions = @((Join-Path $jdk 'bin'), (Join-Path $root 'Android-SDK\platform-tools'),
    (Join-Path $root 'Android-SDK\emulator'), (Join-Path $root 'Android-SDK\cmdline-tools\latest\bin'),
    (Join-Path $root 'Android-SDK\build-tools\36.0.0'), (Join-Path $root 'Android-CLI\bin'))
foreach ($entry in $additions) {
    if ($pathEntries -notcontains $entry) { $pathEntries += $entry }
}
[Environment]::SetEnvironmentVariable('Path', ($pathEntries -join ';'), 'User')
[Environment]::SetEnvironmentVariable('ANDROID_HOME', (Join-Path $root 'Android-SDK'), 'User')
[Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT', (Join-Path $root 'Android-SDK'), 'User')
[Environment]::SetEnvironmentVariable('ANDROID_AVD_HOME', (Join-Path $root 'Android-AVD'), 'User')
[Environment]::SetEnvironmentVariable('ANDROID_USER_HOME', (Join-Path $root 'Android-CLI'), 'User')
[Environment]::SetEnvironmentVariable('JAVA_HOME', $jdk, 'User')
Write-Host 'Saved Android SDK, AVD, CLI, and JDK environment variables for your Windows user. App build and update scripts use APK-DEV\Temp only for their own work. Open a new terminal.'
