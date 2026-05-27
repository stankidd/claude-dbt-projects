# thursday-setup.ps1
# Run AFTER cloning mg-dbt-assessment
# DO NOT start 2-hour clock until dbt debug passes and README is read

Write-Host "=== Mammoth Assessment Thursday Setup ===" -ForegroundColor Cyan
Write-Host "Run this before starting your 2-hour clock" -ForegroundColor Yellow
Write-Host ""

# Step 1: Create venv
if (-not (Test-Path ".venv")) {
    Write-Host "[1/8] Creating Python 3.11 venv..." -ForegroundColor Yellow
    uv venv .venv --python 3.11
    Write-Host "[1/8] Installing pip..." -ForegroundColor Yellow
    & ".venv\Scripts\python.exe" -m ensurepip
} else {
    Write-Host "[1/8] Venv exists - skipping" -ForegroundColor Green
}

# Step 2: Install requirements
Write-Host "[2/8] Installing requirements..." -ForegroundColor Yellow
& ".venv\Scripts\python.exe" -m pip install -r requirements.txt

# Step 3: Configure .env
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "[3/8] Created .env - FILL IN CREDENTIALS NOW" -ForegroundColor Red
    Write-Host "      SNOWFLAKE_ACCOUNT=jua78218" -ForegroundColor White
    Write-Host "      SNOWFLAKE_USER=CANDIDATE_STAN_KIDD" -ForegroundColor White
    Write-Host "      SNOWFLAKE_ROLE=CANDIDATE_STAN_KIDD" -ForegroundColor White
    Write-Host "      SNOWFLAKE_WAREHOUSE=DBT_DEVELOPMENT" -ForegroundColor White
    Write-Host "      SNOWFLAKE_DATABASE=CANDIDATE_TEST" -ForegroundColor White
    Write-Host "      SNOWFLAKE_SCHEMA=CANDIDATE_STAN_KIDD_DEV" -ForegroundColor White
    Write-Host "      SNOWFLAKE_PASSWORD=your-new-password" -ForegroundColor White
    Write-Host ""
    Write-Host "Press any key after filling in .env..." -ForegroundColor Yellow
    pause
} else {
    Write-Host "[3/8] .env exists" -ForegroundColor Green
}

# Step 4: Load env vars
Write-Host "[4/8] Loading environment variables..." -ForegroundColor Yellow
Get-Content .env | ForEach-Object {
    if ($_ -match "^\s*([^#][^=]+)=(.*)$") {
        $key = $matches[1].Trim()
        $val = $matches[2].Trim()
        [Environment]::SetEnvironmentVariable($key, $val, "Process")
        Write-Host "  Loaded: $key" -ForegroundColor Green
    }
}

# Step 5: Write clean .mcp.json
Write-Host "[5/8] Writing clean .mcp.json..." -ForegroundColor Yellow
$projectDir = (Get-Location).Path -replace '\\', '/'
$dbtPath = "$projectDir/.venv/Scripts/dbt.exe"
$mcpJson = "{`n  ""mcpServers"": {`n    ""dbt"": {`n      ""command"": ""uvx"",`n      ""args"": [""dbt-mcp""],`n      ""env"": {`n        ""DBT_PROJECT_DIR"": ""$projectDir"",`n        ""DBT_PATH"": ""$dbtPath""`n      }`n    }`n  }`n}"
[System.IO.File]::WriteAllText(
    (Join-Path (Get-Location).Path ".mcp.json"),
    $mcpJson,
    (New-Object System.Text.UTF8Encoding $false)
)
Write-Host "[5/8] .mcp.json written" -ForegroundColor Green
Write-Host "      DBT_PROJECT_DIR: $projectDir" -ForegroundColor White
Write-Host "      DBT_PATH: $dbtPath" -ForegroundColor White

# Step 6: Copy Claude scaffolding
$scaffoldSource = "C:\Users\Stan\Documents\VScode\mammoth-test\.claude"
if (Test-Path $scaffoldSource) {
    Write-Host "[6/8] Copying Claude scaffolding..." -ForegroundColor Yellow
    Copy-Item $scaffoldSource -Destination ".claude" -Recurse -Force
    Write-Host "[6/8] .claude/ copied from mammoth-test" -ForegroundColor Green
} else {
    Write-Host "[6/8] WARNING: scaffolding not found at $scaffoldSource" -ForegroundColor Red
}

# Step 6b: Remove unrelated client folders
Write-Host "[6b] Cleaning up unrelated client folders..." -ForegroundColor Yellow
$foldersToRemove = @(
    ".claude\project_docs\client-tpch_sf1000",
    ".claude\project_docs\client-tpch_sf10",
    ".claude\project_docs\client-pharma_sales",
    ".claude\project_docs\client-champion_homes"
)
foreach ($folder in $foldersToRemove) {
    if (Test-Path $folder) {
        Remove-Item $folder -Recurse -Force
        Write-Host "  Removed: $folder" -ForegroundColor Green
    }
}
Write-Host "[6b] Unrelated client folders removed" -ForegroundColor Green

# Step 6c: Replace CLAUDE.md with assessment-specific version
Write-Host "[6c] Installing assessment CLAUDE.md..." -ForegroundColor Yellow
$assessmentClaude = "C:\Users\Stan\Documents\VScode\mammoth-test\.claude\project_docs\client-bikeshare\sessions\CLAUDE_assessment.md"
if (Test-Path $assessmentClaude) {
    Copy-Item $assessmentClaude ".claude\CLAUDE.md" -Force
    Write-Host "[6c] Assessment CLAUDE.md installed" -ForegroundColor Green
} else {
    Write-Host "[6c] WARNING: assessment CLAUDE.md not found" -ForegroundColor Red
}

# Step 7: Register MCP with Claude Code
Write-Host "[7/8] Registering MCP server with Claude Code..." -ForegroundColor Yellow
claude mcp remove dbt -s local 2>$null
claude mcp add dbt "$env:USERPROFILE\.local\bin\uvx.exe" dbt-mcp `
    --env DBT_PROJECT_DIR=$projectDir `
    --env DBT_PATH=$dbtPath
Write-Host "[7/8] MCP registered" -ForegroundColor Green

# Step 8: Verify dbt connection
Write-Host "[8/8] Running dbt debug..." -ForegroundColor Yellow
& ".venv\Scripts\dbt.exe" debug

Write-Host ""
Write-Host "=== Pre-clock setup complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "BEFORE STARTING CLOCK:" -ForegroundColor Yellow
Write-Host "  1. Read README.md completely" -ForegroundColor White
Write-Host "  2. Confirm: All checks passed in dbt debug" -ForegroundColor White
Write-Host ""
Write-Host "TO START CLOCK:" -ForegroundColor Yellow
Write-Host "  code ." -ForegroundColor White
Write-Host "  In VS Code terminal:" -ForegroundColor White
Write-Host "  .venv\Scripts\Activate.ps1" -ForegroundColor White
Write-Host "  . .\load-env.ps1" -ForegroundColor White
Write-Host "  claude" -ForegroundColor White
Write-Host "  /mcp  <-- verify dbt shows connected" -ForegroundColor White
Write-Host ""
Write-Host "FIRST CLAUDE CODE COMMAND:" -ForegroundColor Yellow
Write-Host "  Profile all 6 source tables and confirm findings match CLAUDE.md" -ForegroundColor White
Write-Host "  Then: /build-bronze-models .claude/project_docs/client-bikeshare/04-specs/documents/bikeshare-tech-spec.md" -ForegroundColor White