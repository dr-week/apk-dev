param([Parameter(Mandatory)][string]$ArtifactPath)
$ErrorActionPreference = 'Stop'
$artifact = (Resolve-Path -LiteralPath $ArtifactPath).Path
$root = Split-Path $PSScriptRoot -Parent
$jdk = 'C:\Software\Java\Temurin-21\jdk-21.0.12.1+1'
$jar = Get-ChildItem (Join-Path $root 'Tools') -Filter 'bundletool-all-*.jar' -File | Sort-Object Name -Descending | Select-Object -First 1
if (-not $jar) { throw 'Bundletool missing; run Scripts\Update-Android-Toolchain.ps1.' }
$java = Join-Path $jdk 'bin\java.exe'
if (-not (Test-Path $java)) { throw "Java 21 missing: $java" }
$xml = if ([IO.Path]::GetExtension($artifact) -eq '.apk') {
    $analyzer = Join-Path $root 'Android-SDK\cmdline-tools\latest\bin\apkanalyzer.bat'
    if (-not (Test-Path $analyzer)) { throw "APK Analyzer missing: $analyzer" }
    $package = (& $analyzer manifest application-id $artifact | Select-Object -Last 1).Trim()
    $version = (& $analyzer manifest version-name $artifact | Select-Object -Last 1).Trim()
    $code = (& $analyzer manifest version-code $artifact | Select-Object -Last 1).Trim()
    "<manifest package=`"$package`" xmlns:android=`"http://schemas.android.com/apk/res/android`" android:versionName=`"$version`" android:versionCode=`"$code`" />"
} else {
    & $java -jar $jar.FullName dump manifest "--bundle=$artifact" --module=base
}
if ($LASTEXITCODE -ne 0) { throw 'Could not read Android App Bundle manifest.' }
[xml]$document = $xml -join "`n"
$node = $document.SelectSingleNode('/manifest')
if (-not $node) { throw 'Artifact manifest has no root manifest element.' }
$ns = 'http://schemas.android.com/apk/res/android'
$code = $node.GetAttribute('versionCode', $ns)
if (-not $node.GetAttribute('package') -or -not $code) { throw 'Artifact package/version metadata is incomplete.' }
[pscustomobject]@{
    packageName = $node.GetAttribute('package')
    versionName = $node.GetAttribute('versionName', $ns)
    versionCode = [int]$code
}
