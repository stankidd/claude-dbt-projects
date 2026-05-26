# setup-assessment.ps1
# Generic setup for any dbt assessment repo
# Run from inside the cloned repo

Write-Host "=== Assessment Setup ===" -ForegroundColor Cyan

if (-not (Test-Path ".venv")) {
    Write-Host "Creating Python 3.11 venv..." -ForegroundColor Yellow
    uv venv .venv --python 3.11
    & ".venv\Scripts\python.exe" -m ensurepip
} else {
    Write-Host "Venv exists" -ForegroundColor Green
}

Write-Host "Installing requirements..." -ForegroundColor Yellow
& ".venv\Scripts\python.exe" -m pip install -r requirements.txt

if (Test-Path ".env") {
    Get-Content .env | ForEach-Object {
        if ($_ -match "^\s*([^#][^=]+)=(.*)`$") {
            $key = $matches[1].Trim()
            $val = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($key, $val, "Process")
            Write-Host "Loaded: $key" -ForegroundColor Green
        }
    }
} else {
    Write-Host "WARNING: .env not found - copy .env.example to .env" -ForegroundColor Red
}

& ".venv\Scripts\dbt.exe" debug

Write-Host "Setup complete" -ForegroundColor Cyan
