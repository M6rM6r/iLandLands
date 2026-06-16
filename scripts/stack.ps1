#Requires -Version 5.1
<#
.SYNOPSIS
  Gulf Lands dev stack orchestration (Windows).
#>
param(
    [ValidateSet('up', 'down', 'logs', 'test', 'verify', 'seed')]
    [string]$Action = 'up'
)

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

switch ($Action) {
    'up'    { docker compose up -d; Write-Host 'Stack: http://localhost (PHP) :8000 (Python) :8001 (Reco) :8002 (Analytics)' }
    'down'  { docker compose down }
    'logs'  { docker compose logs -f backend-python reco-service analytics }
    'test'  {
        flutter analyze
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        flutter test
        Push-Location backend-python; pytest -v; Pop-Location
    }
    'verify' { python scripts/verify_integrity.py }
    'seed'   { node scripts/seed_firestore.js }
}
