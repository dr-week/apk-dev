function ConvertTo-Base64Url([byte[]]$Bytes) {
    [Convert]::ToBase64String($Bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

function Get-PlayAccessToken([string]$CredentialPath) {
    $service = Get-Content -LiteralPath $CredentialPath -Raw | ConvertFrom-Json
    foreach ($field in @('client_email', 'private_key', 'token_uri')) {
        if (-not $service.$field) { throw "Service account JSON missing '$field'." }
    }
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $header = @{ alg = 'RS256'; typ = 'JWT' } | ConvertTo-Json -Compress
    $claims = @{ iss = $service.client_email; scope = 'https://www.googleapis.com/auth/androidpublisher'; aud = $service.token_uri; iat = $now; exp = $now + 3600 } | ConvertTo-Json -Compress
    $body = (ConvertTo-Base64Url ([Text.Encoding]::UTF8.GetBytes($header))) + '.' +
        (ConvertTo-Base64Url ([Text.Encoding]::UTF8.GetBytes($claims)))
    $rsa = [Security.Cryptography.RSA]::Create()
    try {
        $rsa.ImportFromPem($service.private_key)
        $signature = $rsa.SignData([Text.Encoding]::UTF8.GetBytes($body),
            [Security.Cryptography.HashAlgorithmName]::SHA256,
            [Security.Cryptography.RSASignaturePadding]::Pkcs1)
    } finally { $rsa.Dispose() }
    $assertion = "$body.$(ConvertTo-Base64Url $signature)"
    $response = Invoke-RestMethod -Method Post -Uri $service.token_uri `
        -ContentType 'application/x-www-form-urlencoded' -Body @{
            grant_type = 'urn:ietf:params:oauth:grant-type:jwt-bearer'
            assertion = $assertion
        }
    $response.access_token
}
