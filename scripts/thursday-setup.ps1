# thursday-setup.ps1
# Run AFTER cloning mg-dbt-assessment
# DO NOT start 2-hour clock until dbt debug passes

Write-Host "=== Mammoth Assessment Thursday Setup ===" -ForegroundColor Cyan
Write-Host "Run this before starting your 2-hour clock" -ForegroundColor Yellow
Write-Host ""

# Step 1: Create venv
if (-not (Test-Path ".venv")) {
    Write-Host "[1/7] Creating Python 3.11 venv..." -ForegroundColor Yellow
    uv venv .venv --python 3.11
    & ".venv\Scripts\python.exe" -m ensurepip
} else {
    Write-Host "[1/7] Venv exists" -ForegroundColor Green
}

# Step 2: Install requirements
Write-Host "[2/7] Installing requirements..." -ForegroundColor Yellow
& ".venv\Scripts\python.exe" -m pip install -r requirements.txt

# Step 3: Configure .env
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "[3/7] Created .env - FILL IN CREDENTIALS NOW" -ForegroundColor Red
    Write-Host "      SNOWFLAKE_ACCOUNT=jua78218" -ForegroundColor White
    Write-Host "      SNOWFLAKE_USER=CANDIDATE_STAN_KIDD" -ForegroundColor White
    Write-Host "      SNOWFLAKE_ROLE=CANDIDATE_STAN_KIDD" -ForegroundColor White
    Write-Host "      SNOWFLAKE_WAREHOUSE=DBT_DEVELOPMENT" -ForegroundColor White
    Write-Host "      SNOWFLAKE_DATABASE=CANDIDATE_TEST" -ForegroundColor White
    Write-Host "      SNOWFLAKE_SCHEMA=CANDIDATE_STAN_KIDD_DEV" -ForegroundColor White
    Write-Host "      SNOWFLAKE_PASSWORD=your-new-password" -ForegroundColor White
    pause
} else {
    Write-Host "[3/7] .env exists" -ForegroundColor Green
}

# Step 4: Load env vars
Write-Host "[4/7] Loading environment variables..." -ForegroundColor Yellow
Get-Content .env | ForEach-Object {
    if ($_ -match "^\s*([^#][^=]+)=(.*)`$") {
        $key = $matches[1].Trim()
        $val = $matches[2].Trim()
        [Environment]::SetEnvironmentVariable($key, $val, "Process")
        Write-Host "  Loaded: $key" -ForegroundColor Green
    }
}

# Step 5: Write clean .mcp.json
Write-Host "[5/7] Writing clean .mcp.json..." -ForegroundColor Yellow
$projectDir = (Get-Location).Path -replace '\\\\', '/'
$dbtPath = "$projectDir/.venv/Scripts/dbt.exe"
$mcpContent = "{
  ``\"mcpServers\"``: {
    ``\"dbt\"``: {
      ``\"command\"``: ``\"uvx\"``,
      ``\"args\"``: [``\"dbt-mcp\"``],
      ``\"env\"``: {
        ``\"DBT_PROJECT_DIR\"``: ``\"$projectDir\"``,
        ``\"DBT_PATH\"``: ``\"$dbtPath\"````n      }
    }
  }
}"
[System.IO.File]::WriteAllText((Join-Path (Get-Location).Path ".mcp.json"), $mcpContent, (New-Object System.Text.UTF8Encoding $false))
Write-Host "[5/7] .mcp.json written" -ForegroundColor Green
Write-Host "      DBT_PROJECT_DIR: $projectDir" -ForegroundColor White
Write-Host "      DBT_PATH: $dbtPath" -ForegroundColor White

# Step 6: Copy Claude scaffolding
$scaffoldSource = "C:\Users\Stan\Documents\VScode\mammoth-test\.claude"
if (Test-Path $scaffoldSource) {
    Write-Host "[6/7] Copying Claude scaffolding..." -ForegroundColor Yellow
    Copy-Item $scaffoldSource -Destination ".claude" -Recurse -Force
    Write-Host "[6/7] .claude/ copied from mammoth-test" -ForegroundColor Green
} else {
    Write-Host "[6/7] WARNING: scaffolding not found at $scaffoldSource" -ForegroundColor Red
}

# Step 7: Verify dbt connection
Write-Host "[7/7] Running dbt debug..." -ForegroundColor Yellow
& ".venv\Scripts\dbt.exe" debug

Write-Host "" 
Write-Host "=== Pre-clock setup complete ===" -ForegroundColor Cyan
Write-Host "" 
Write-Host "BEFORE STARTING CLOCK:" -ForegroundColor Yellow
Write-Host "  1. Read README.md completely" -ForegroundColor White
Write-Host "  2. Confirm: All checks passed in dbt debug" -ForegroundColor White
Write-Host "" 
Write-Host "TO START CLOCK - open VS Code:" -ForegroundColor Yellow
Write-Host "  code ." -ForegroundColor White
Write-Host "  In VS Code terminal:" -ForegroundColor White
Write-Host "  .venv\Scripts\Activate.ps1" -ForegroundColor White
Write-Host "  . .\load-env.ps1" -ForegroundColor White
Write-Host "  claude" -ForegroundColor White
Write-Host "" 
Write-Host "FIRST COMMAND IN CLAUDE CODE:" -ForegroundColor Yellow
Write-Host "  Profile all 6 source tables and capture notes in CLAUDE.md" -ForegroundColor White
