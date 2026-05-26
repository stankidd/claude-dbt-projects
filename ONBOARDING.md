# Welcome to the Mammoth Growth Agentic dbt Workflow
## Onboarding Guide for New Engineers

---

## What This Repo Is

This repo is a **Claude Code scaffolded dbt project** that implements the Mammoth Growth
agentic analytics engineering workflow. It combines:

- A **dbt project** with a medallion architecture (Bronze → Silver → Gold)
- A **Claude Code scaffolding** (`.claude/`) that encodes Mammoth's engineering standards
- A **dbt MCP server** that gives Claude Code the ability to run dbt commands autonomously
- A **multi-project structure** supporting multiple client engagements in one repo

The result is a workflow where you write a BRD, run a slash command, and Claude Code
builds the entire data pipeline — profiling source data, writing SQL, running tests,
fixing failures, and pushing a PR — with you reviewing as the senior engineer.

---

## Repo Structure at a Glance

```
mammoth-test/
├── .claude/                    ← Claude Code scaffolding (NEVER ships to production)
│   ├── CLAUDE.md               ← Standing orders — first thing Claude reads every session
│   ├── skills/                 ← Encoded engineering best practices (10 skills)
│   ├── commands/               ← Slash commands available in Claude Code (20+)
│   ├── ai_docs/external/       ← Claude Code + dbt reference documentation (26 files)
│   └── project_docs/           ← Client documentation organized by engagement
│       ├── client-tpch_sf1000/ ← Order analytics client
│       ├── client-tpch_sf10/   ← Supplier performance client
│       ├── client-pharma_sales/← Pharma sales effectiveness client
│       └── client-champion_homes/ ← Enterprise performance management client
│
├── models/                     ← dbt project (THIS ships to production)
│   ├── tpch_sf1000/            ← Order analytics pipeline
│   │   ├── bronze/             ← Raw source data, views
│   │   ├── silver/             ← Cleaned and conformed, tables
│   │   └── gold/               ← Business metrics, tables
│   ├── tpch_sf10/              ← Supplier performance pipeline
│   ├── pharma_sales/           ← Sales effectiveness pipeline
│   └── champion_homes/         ← Enterprise performance pipeline (pending)
│
├── seeds/pharma_sales/         ← CSV seed data for pharma_sales project
├── macros/                     ← generate_schema_name.sql (multi-project schema isolation)
├── dbt_project.yml             ← dbt configuration for all 4 projects
├── .mcp.json                   ← MCP server configuration (project-scoped)
├── .env.mcp                    ← MCP environment variables (gitignored)
└── .env                        ← Snowflake credentials (gitignored)
```

---

## Prerequisites

Before setting up this repo, install the following:

| Tool | Version | Purpose | Install Command |
|------|---------|---------|-----------------|
| Node.js | LTS | Required for Claude Code CLI | nodejs.org |
| Claude Code CLI | Latest | Agentic development terminal | `npm install -g @anthropic-ai/claude-code` |
| uv | Latest | Python version manager | `pip install uv` |
| dbt Core (Python 3.12) | 1.11.x | Local dbt builds via MCP | `uv tool install --with dbt-snowflake dbt-core --python 3.12` |
| dbt Cloud CLI | Latest | dbt Cloud authentication | Download from github.com/dbt-labs/dbt-cli/releases |
| Git | Latest | Version control | git-scm.com |

> **Important:** Install dbt Core via uv with Python 3.12 explicitly.
> Python 3.13+ has a mashumaro incompatibility that breaks dbt imports.

---

## Step 1 — Clone the Repo

```powershell
git clone https://github.com/stankidd/mammoth_test.git
cd mammoth-test
```

---

## Step 2 — Configure Snowflake Credentials

Copy the environment template and fill in your credentials:

```powershell
Copy-Item .env.sample .env
```

Edit `.env` with your Snowflake details:

```
SNOWFLAKE_ACCOUNT=your-account-identifier
SNOWFLAKE_USER=your-username
SNOWFLAKE_PASSWORD=your-password
SNOWFLAKE_ROLE=your-role
SNOWFLAKE_WAREHOUSE=MAMMOTH_WH
SNOWFLAKE_DATABASE=MAMMOTH_DB
SNOWFLAKE_SCHEMA=MAMMOTH_SCHEMA
DBT_TARGET=dev
```

Then create `C:\Users\YourName\.dbt\profiles.yml`:

```yaml
mammoth_test:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: your-account-identifier
      user: your-username
      password: your-password
      role: your-role
      warehouse: MAMMOTH_WH
      database: MAMMOTH_DB
      schema: MAMMOTH_SCHEMA
      threads: 4
```

---

## Step 3 — Configure dbt Cloud

Download your `dbt_cloud.yml` from the dbt Cloud UI:

1. Go to your dbt Cloud account
2. Click **Profile Settings** → **dbt CLI** section
3. Click **Download dbt_cloud.yml**
4. Save to `C:\Users\YourName\.dbt\dbt_cloud.yml`

Add the project ID to `dbt_project.yml` at the bottom:

```yaml
dbt-cloud:
  project-id: "your-project-id"
```

Verify the connection:

```powershell
dbt debug
```

All checks should pass before proceeding.

---

## Step 4 — Configure the MCP Server

Create your `.env.mcp` file (this is gitignored — never commit it):

```powershell
@"
DBT_PROJECT_DIR=C:/Users/YourName/path/to/mammoth-test
DBT_PATH=C:/Users/YourName/.local/bin/dbt.exe
DBT_HOST=your-dbt-cloud-host
DBT_TOKEN=your-dbt-cloud-token
DBT_PROD_ENV_ID=your-environment-id
"@ | Set-Content ".env.mcp"
```

Register the MCP server with Claude Code:

```powershell
claude mcp add dbt "C:\Users\YourName\.local\bin\uvx.exe" dbt-mcp `
  --env-file "C:\path\to\mammoth-test\.env.mcp"
```

Verify the MCP server is connected:

```powershell
claude
```

Then type `/mcp` — you should see:
```
dbt · ✔ connected · 47 tools
```

---

## Step 5 — Load the Seeds

The pharma_sales project uses dbt seed data. Load it before building:

```powershell
dbt seed --select pharma_sales
```

---

## Step 6 — Verify Everything Works

Run a quick build to confirm the full stack is connected:

```powershell
dbt build --select tag:tpch_sf10
```

Should return: `PASS=X WARN=0 ERROR=0`

Then open Claude Code and verify MCP tools:

```powershell
claude
```

Type `/mcp` and confirm 47 tools are connected.

---

## The Agentic Workflow

This is the core workflow you will use for every new client engagement:

### Phase 1 — Discovery (Human Only)
Meet with the client. Understand the business problem. Identify data sources.

### Phase 2 — Business Requirements Document
Write a BRD capturing metrics, data sources, grain definitions, and business rules.
Save it to: `.claude/project_docs/client-name/03-requirements/brd.md`

### Phase 3 — Technical Specification
Let Claude Code convert the BRD to a tech spec:

```
/tech-spec-plan .claude/project_docs/client-name/03-requirements/brd.md
```

Claude will:
- Profile all source tables via `dbt_show`
- Design bronze → silver → gold models
- Write the complete tech spec to `04-specs/`

Validate the spec before building:

```
/validate-spec .claude/project_docs/client-name/04-specs/tech-spec.md
```

### Phase 4 — Agentic Build
Run the full pipeline build:

```
/build-full-spec .claude/project_docs/client-name/04-specs/tech-spec.md
```

Or build layer by layer for more control:

```
/build-bronze-models .claude/project_docs/client-name/04-specs/tech-spec.md
/build-silver-models .claude/project_docs/client-name/04-specs/tech-spec.md
/build-gold-models   .claude/project_docs/client-name/04-specs/tech-spec.md
```

Claude will write all SQL, run `dbt build`, fix any failures autonomously, and
report when each layer is complete.

### Phase 5 — Review and Push PR
Review Claude's output as the senior engineer, then push:

```
/github-create-pr
```

Claude creates the branch, commits, pushes, and opens a PR using the Mammoth template.
You review and merge. No code reaches production without human approval.

---

## Available Slash Commands

### Build Commands
| Command | Purpose |
|---------|---------|
| `/build-bronze-models [spec]` | Build bronze layer from tech spec |
| `/build-silver-models [spec]` | Build silver layer from tech spec |
| `/build-gold-models [spec]` | Build gold layer from tech spec |
| `/build-full-spec [spec]` | Build all layers end to end |
| `/build [selector]` | Run dbt build on a specific selector |

### Planning Commands
| Command | Purpose |
|---------|---------|
| `/tech-spec-plan [brd]` | Convert BRD to tech spec |
| `/validate-spec [spec]` | Validate spec completeness before building |
| `/metaprompt-workflow [task]` | Generate optimized prompt for complex tasks |

### Data Profiling Commands
| Command | Purpose |
|---------|---------|
| `/data-profile [table]` | Profile a complete table |
| `/profile-column [table.column]` | Profile a single column |
| `/profile-domain [table.column]` | Profile categorical values |
| `/profile-plan [spec]` | Full profiling plan for all sources |
| `/profile-table-relationships [spec]` | Profile all joins in a spec |

### Git and PR Commands
| Command | Purpose |
|---------|---------|
| `/github-create-pr` | Create PR with Mammoth template |
| `/git-create-branch [name]` | Create feature branch |
| `/git-commit [files]` | Stage and commit specific files |
| `/git-commit-all` | Stage and commit all changes |

### Session Management Commands
| Command | Purpose |
|---------|---------|
| `/clock-out` | End session, save context, commit WIP |
| `/save-context [label]` | Save session progress to file |
| `/load-ai-docs [topic]` | Load relevant reference docs into context |
| `/all-tools` | List all available MCP tools and commands |
| `/read-conditional-docs [task]` | Load only docs relevant to current task |

---

## Available Skills

Skills are markdown files in `.claude/skills/` that Claude loads before executing tasks.
They encode Mammoth's engineering standards so every build follows the same patterns.

| Skill | Status | Purpose |
|-------|--------|---------|
| `dbt-best-practices` | Complete | 60+ SQL and dbt coding standards |
| `tech-spec-plan` | Complete | BRD to tech spec conversion |
| `validate-tech-spec` | Complete | Pre-build quality gate |
| `dbt-implementation-validator` | Complete | Pre-flight checklist before building |
| `data-profiling` | Complete | Source data discovery and profiling |
| `build-from-spec` | Complete | Spec to SQL execution engine |
| `pr-from-spec` | Complete | PR creation workflow |
| `git` | Placeholder | Branch and commit conventions |
| `dbt-planning-router` | Placeholder | Routes requests to correct command |
| `meta-skill` | Placeholder | How Claude loads and applies skills |

---

## Active Projects

| Project | Source | Models | Tests | Status |
|---------|--------|--------|-------|--------|
| tpch_sf1000 | SNOWFLAKE_SAMPLE_DATA.TPCH_SF1000 | 11 | 40+ | Complete |
| tpch_sf10 | SNOWFLAKE_SAMPLE_DATA.TPCH_SF10 | 11 | 40+ | Complete |
| pharma_sales | MAMMOTH_DB seeds | 11 | 57 | Complete |
| champion_homes | TBD | 0 | 0 | Structure ready |

---

## Adding a New Client Project

Follow these steps for every new client engagement:

### 1 — Create the folder structure
Ask Claude Code to do it:
```
Create the project folder structure for a new client called client-name
following the same pattern as existing clients in this repo.
```

### 2 — Update dbt_project.yml
Add the new project under `models:` following the existing pattern:
```yaml
client_name:
  bronze:
    +materialized: view
    +tags: ['bronze', 'client_name']
    +schema: client_name_bronze
  silver:
    +materialized: table
    +tags: ['silver', 'client_name']
    +schema: client_name_silver
  gold:
    +materialized: table
    +tags: ['gold', 'client_name']
    +schema: client_name_gold
```

### 3 — Create the sources file
Add `models/client_name/bronze/client_name_sources.yml` pointing at the
client's source database and schema.

### 4 — Write the BRD
Save to `.claude/project_docs/client-client_name/03-requirements/brd.md`

### 5 — Run the workflow
```
/tech-spec-plan → /validate-spec → /build-full-spec → /github-create-pr
```

---

## Schema Naming Convention

The `macros/generate_schema_name.sql` macro controls schema names:

| Environment | Schema Pattern | Example |
|-------------|---------------|---------|
| dev | `MAMMOTH_SCHEMA_project_layer` | `MAMMOTH_SCHEMA_tpch_sf10_bronze` |
| prod | `project_layer` | `TPCH_SF10_BRONZE` |

The target name `prod` in dbt Cloud triggers the clean production naming.

---

## Viewing the DAG

Generate and serve documentation locally:

```powershell
dbt docs generate
dbt docs serve
```

Open `http://localhost:8080` in your browser to see the full lineage DAG
showing all pipelines from source through bronze, silver, to gold.

---

## Git Workflow

```
1. Create a feature branch:     sk/use-case-name
2. Build models agentically
3. All tests must pass before committing
4. Push PR via /github-create-pr
5. Engineer reviews and merges
6. Never commit directly to main
```

Branch naming: `initials/use-case-name` (e.g. `sk/pharma-sales-effectiveness`)

---

## Getting Help

- **CLAUDE.md** — project standing orders and source data reference
- **ai_docs/external/** — Claude Code and dbt documentation
- **skills/** — detailed instructions for each phase of the workflow
- **project_docs/** — client BRDs and tech specs for reference

When in doubt, ask Claude Code:
```
Read the dbt-best-practices skill and tell me the correct way to [task]
```

---

## Key Contacts

| Role | Name |
|------|------|
| Engineer | Stan Kidd (sk) |
| dbt Cloud Account | stankidd@yahoo.com |
| GitHub | github.com/stankidd/mammoth_test |

---

*This onboarding guide was generated from the Mammoth Growth agentic dbt workflow
scaffolding. For questions about the workflow, refer to the skills in .claude/skills/
or the AI docs in .claude/ai_docs/external/.*
