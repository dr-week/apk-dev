param([Parameter(Mandatory)][string]$PackageName)
$root = Split-Path $PSScriptRoot -Parent
$database = Join-Path $root 'Transport\Database\releases.sqlite3'
$registry = Join-Path $PSScriptRoot 'release_registry.py'
& python $registry --database $database list | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Could not initialize release registry.' }
$query = "import sqlite3,sys; d=sqlite3.connect(sys.argv[1]); r=d.execute('select coalesce(max(version_code),0)+1 from releases where package=?',(sys.argv[2],)).fetchone(); print(r[0])"
& python -c $query $database $PackageName
if ($LASTEXITCODE -ne 0) { throw 'Version registry query failed.' }
