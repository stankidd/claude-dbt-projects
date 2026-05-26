# load-env.ps1
# Windows equivalent of: set -a; source .env; set +a
# Usage: . .\load-env.ps1

if (-not (Test-Path ".env")) {
    Write-Host "ERROR: .env file not found" -ForegroundColor Red
    return
}

Get-Content .env | ForEach-Object {
    if ($_ -match "^\s*([^#][^=]+)=(.*)`$") {
        $key = $matches[1].Trim()
        $val = $matches[2].Trim()
        [Environment]::SetEnvironmentVariable($key, $val, "Process")
        Write-Host "Loaded: $key" -ForegroundColor Green
    }
}

Write-Host "" 
Write-Host "All env vars loaded. Run dbt debug to verify." -ForegroundColor Cyan
