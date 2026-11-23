param()
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$database = Join-Path $root 'Transport\Database\releases.sqlite3'
& python (Join-Path $PSScriptRoot 'release_registry.py') --database $database list
if ($LASTEXITCODE -ne 0) { throw 'Could not read release history.' }
