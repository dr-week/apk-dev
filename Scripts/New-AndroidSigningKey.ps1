param(
    [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]*$')][string]$AppName,
    [string]$Alias = 'upload',
    [switch]$GenerateProtectedPassword
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$keytool = 'C:\Software\Java\Temurin-21\jdk-21.0.12.1+1\bin\keytool.exe'
if (-not (Test-Path $keytool)) { throw "JDK keytool missing: $keytool" }
$folder = Join-Path $root "Secrets\$AppName"
New-Item -ItemType Directory -Path $folder -Force | Out-Null
$keystore = Join-Path $folder "$AppName-upload.p12"
if (Test-Path $keystore) { throw "Refusing to overwrite signing key: $keystore" }
if ($GenerateProtectedPassword) {
    $passwordFile = Join-Path $folder 'upload-key-password.dpapi'
    if (Test-Path $passwordFile) { throw "Refusing to overwrite protected key password: $passwordFile" }
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    $acl = Get-Acl $folder
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($rule in @($acl.Access)) { [void]$acl.RemoveAccessRule($rule) }
    $acl.SetOwner([Security.Principal.NTAccount]$identity)
    foreach ($trustee in @($identity, 'NT AUTHORITY\SYSTEM')) {
        $rule = [Security.AccessControl.FileSystemAccessRule]::new(
            $trustee, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
        $acl.AddAccessRule($rule)
    }
    Set-Acl -Path $folder -AclObject $acl
    $bytes = New-Object byte[] 32
    $random = [Security.Cryptography.RandomNumberGenerator]::Create()
    $random.GetBytes($bytes)
    $random.Dispose()
    $password = [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
    $secure = ConvertTo-SecureString $password -AsPlainText -Force
    ConvertFrom-SecureString $secure | Set-Content -LiteralPath $passwordFile -Encoding ascii
    $env:APK_DEV_UPLOAD_KEY_PASSWORD = $password
    try {
        & $keytool -genkeypair -noprompt -keystore $keystore -storetype PKCS12 -alias $Alias `
            -keyalg RSA -keysize 4096 -validity 10000 -dname "CN=$AppName, O=App Publisher, C=IN" `
            -storepass:env APK_DEV_UPLOAD_KEY_PASSWORD -keypass:env APK_DEV_UPLOAD_KEY_PASSWORD
        if ($LASTEXITCODE -ne 0) { throw 'Signing key generation failed.' }
    } catch {
        Remove-Item -LiteralPath $keystore,$passwordFile -Force -ErrorAction SilentlyContinue
        throw
    } finally { Remove-Item Env:APK_DEV_UPLOAD_KEY_PASSWORD -ErrorAction SilentlyContinue }
    Write-Host "Created protected app upload key: $keystore"
    Write-Host 'The password is encrypted for this Windows account. Back up the key and password securely before public release.'
    return
}
Write-Host 'keytool will prompt for keystore and certificate details. Do not reuse another app key.'
& $keytool -genkeypair -keystore $keystore -storetype PKCS12 -alias $Alias -keyalg RSA -keysize 4096 -validity 10000
if ($LASTEXITCODE -ne 0) { throw 'Signing key generation failed.' }
Write-Host "Created app-specific upload key: $keystore. Back it up securely."
