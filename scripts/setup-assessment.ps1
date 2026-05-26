# setup-assessment.ps1
# Run ONCE after cloning the Mammoth assessment repo
# Usage: cd mg-dbt-assessment then run this script

Write-Host "=== Mammoth Growth Assessment Setup ===" -ForegroundColor Cyan

# Step 1: Create venv
if (-not (Test-Path ".venv")) {
    Write-Host "Creating Python 3.11 venv..." -ForegroundColor Yellow
    uv venv .venv --python 3.11
    Write-Host "Installing pip..." -ForegroundColor Yellow
    & ".venv\Scripts\python.exe" -m ensurepip
} else {
    Write-Host "Venv exists - skipping" -ForegroundColor Green
}

# Step 2: Install requirements
Write-Host "Installing requirements..." -ForegroundColor Yellow
& ".venv\Scripts\python.exe" -m pip install -r requirements.txt

# Step 3: Load .env
if (Test-Path ".env") {
    Write-Host "Loading .env..." -ForegroundColor Yellow
    Get-Content .env | ForEach-Object {
        if ($_ -match "^\s*([^#][^=]+)=(.*)`$") {
            $key = $matches[1].Trim()
            $val = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($key, $val, "Process")
            Write-Host "  Loaded: $key" -ForegroundColor Green
        }
    }
} else {
    Write-Host "WARNING: .env not found - copy .env.example to .env" -ForegroundColor Red
}

# Step 4: Verify
Write-Host "
Running dbt debug..." -ForegroundColor Yellow
& ".venv\Scripts\dbt.exe" debug

Write-Host "
=== Setup Complete ===" -ForegroundColor Cyan
Write-Host "Next: code . then in VS Code terminal:" -ForegroundColor White
Write-Host "  .venv\Scripts\Activate.ps1" -ForegroundColor White
Write-Host "  . .\load-env.ps1" -ForegroundColor White
Write-Host "  claude" -ForegroundColor White
