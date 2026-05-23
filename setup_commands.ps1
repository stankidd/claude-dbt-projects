$base = "C:\Users\Stan\Documents\VScode\mammoth-dbt-ops-reporting"
$cmd  = "$base\.claude\commands"

# ─────────────────────────────────────────────
# CREATE SUBFOLDERS
# ─────────────────────────────────────────────
New-Item -ItemType Directory -Path "$cmd\tusk" -Force | Out-Null
New-Item -ItemType Directory -Path "$cmd\utils" -Force | Out-Null

# ─────────────────────────────────────────────
# TUSK FOLDER
# ─────────────────────────────────────────────

@"
# Tusk Folder

Tusk commands integrate Claude Code with ticket/task management systems
(Linear, GitHub Issues, Jira). Commands in this folder allow agents to
read tickets, create branches, update statuses, and link PRs to issues
automatically as part of the agentic build workflow.

## Available Commands
See individual .md files in this folder for each command.
"@ | Set-Content "$cmd\tusk\README.md"

# ─────────────────────────────────────────────
# UTILS FOLDER
# ─────────────────────────────────────────────

@"
# Utils Folder

Utility commands that support the main build workflow.
These are helper commands called by other commands or
used for maintenance, diagnostics, and context management.
"@ | Set-Content "$cmd\utils\README.md"

# ─────────────────────────────────────────────
# COMMAND FILES
# ─────────────────────────────────────────────

# all_tools.md
@"
---
description: List all available MCP tools and slash commands in this session
allowed-tools: Bash(*)
---

# /all-tools

List every tool and slash command currently available in this Claude Code session.

## Steps

1. List all MCP servers and their exposed tools:
   - Run: ``claude mcp list``
   - For each server, show the tools it exposes

2. List all custom slash commands from .claude/commands/

3. List all skills from .claude/skills/

4. Show built-in Claude Code commands

## Output Format

Print a structured summary:

``````
=== MCP TOOLS ===
[server-name]
  - tool_name: description

=== CUSTOM COMMANDS ===
/command-name: description

=== SKILLS ===
/skill-name: description

=== BUILT-IN COMMANDS ===
/clear, /compact, /model, /review, /status, /usage ...
``````

This command is useful at the start of a new session to confirm
all expected tools are connected before beginning a build task.
"@ | Set-Content "$cmd\all_tools.md"

# bug_plan.md
@"
---
description: Diagnose a failing dbt model or test and create a fix plan
allowed-tools: Read(*), Bash(dbt*), mcp__dbt__dbt_build, mcp__dbt__dbt_show, mcp__dbt__dbt_test
---

# /bug-plan

Diagnose a failing dbt model or test and produce a structured fix plan.

## Usage
/bug-plan `$ARGUMENTS

Where `$ARGUMENTS is the model name or error description.

## Steps

1. **Read the error**
   - If a model name is given, run: ``dbt build --select `$ARGUMENTS``
   - Capture the full error output

2. **Inspect the model**
   - Read the SQL file for the failing model
   - Read its schema.yml for test definitions
   - Identify the failing test or compilation error

3. **Query the data**
   - Use dbt show to inspect the underlying source data
   - Check for nulls, unexpected values, or schema mismatches

4. **Root cause analysis**
   Identify which of these caused the failure:
   - Column does not exist in source
   - Data type mismatch
   - Test accepted_values does not match actual data
   - Upstream model not built yet
   - Business logic error in SQL
   - Jinja/macro syntax error

5. **Produce fix plan**
   Output a numbered list of exact changes needed:
   - File to edit
   - Line to change
   - What to change it to
   - Why

6. **Ask for approval before making changes**
   Present the plan and wait for confirmation before editing any files.
"@ | Set-Content "$cmd\bug_plan.md"

# build-bronze-models.md
@"
---
description: Build all bronze models defined in a tech spec using the dbt MCP server
allowed-tools: Read(*), Edit(*), Bash(dbt*), mcp__dbt__dbt_build, mcp__dbt__dbt_show, mcp__dbt__dbt_test
---

# /build-bronze-models

Build all bronze layer dbt models from a technical specification.

## Usage
/build-bronze-models `$ARGUMENTS

Where `$ARGUMENTS is the path to the tech spec file.

## Pre-Flight
Load and follow these skills before starting:
- skills/dbt-implementation-validator (pre-flight checklist)
- skills/dbt-best-practices (60+ coding rules)

## Steps

1. **Read the tech spec**
   - Open `$ARGUMENTS and locate the Bronze Models section
   - Create a to-do list of every bronze model to build

2. **Understand the raw data**
   - For each source table, use dbt show via MCP to query 10 rows
   - Confirm column names match what the tech spec expects
   - Note any discrepancies

3. **Define sources**
   - Create or update models/sources/sources.yml
   - Add all new source tables referenced by bronze models

4. **Build each bronze model**
   For every model in the to-do list:
   - Create the .sql file in models/bronze/
   - Follow bronze rules: no business logic, parse raw only, capitalize SQL keywords
   - Add column documentation to schema.yml
   - Check off the model when complete

5. **Validate**
   - Run: dbt build --select tag:bronze (or each model name)
   - If tests fail: use dbt show to query the data, understand why, fix, rerun
   - All tests must pass before proceeding

6. **Summary**
   Report which models were built, which tests passed, and any decisions made.
"@ | Set-Content "$cmd\build-bronze-models.md"

# build-full-spec.md
@"
---
description: Build all layers (bronze, silver, gold) from a tech spec in one agentic run
allowed-tools: Read(*), Edit(*), Bash(dbt*), Bash(git*), mcp__dbt__dbt_build, mcp__dbt__dbt_show, mcp__dbt__dbt_test
---

# /build-full-spec

Build the complete data pipeline (bronze -> silver -> gold) from a tech spec
in a single end-to-end agentic run.

## Usage
/build-full-spec `$ARGUMENTS

Where `$ARGUMENTS is the path to the tech spec file.

## Warning
This command runs the full build autonomously. Use it only when:
- The tech spec is complete and validated (/validate-spec first)
- You have reviewed the data profile (/data-profile first)
- You are comfortable with a 20-40 minute unattended run

For more control, run /build-bronze-models, /build-silver-models,
and /build-gold-models separately with review between each layer.

## Steps

1. **Load skills**
   - skills/dbt-implementation-validator
   - skills/dbt-best-practices

2. **Read and plan**
   - Read `$ARGUMENTS completely
   - Create a full to-do list across all three layers

3. **Build bronze** (same as /build-bronze-models)
   - Define sources
   - Build all bronze models
   - Validate with dbt build

4. **Build silver** (fresh context approach)
   - Build all silver models referencing bronze
   - Validate with dbt build

5. **Build gold**
   - Build all gold models referencing silver
   - Validate with dbt build

6. **Push PR**
   - Run /pr-from-spec to create the PR automatically

7. **Final summary**
   Report all models built, all tests passed, and PR link.
"@ | Set-Content "$cmd\build-full-spec.md"

# build-gold-models.md
@"
---
description: Build all gold models defined in a tech spec using the dbt MCP server
allowed-tools: Read(*), Edit(*), Bash(dbt*), mcp__dbt__dbt_build, mcp__dbt__dbt_show, mcp__dbt__dbt_test
---

# /build-gold-models

Build all gold layer dbt models from a technical specification.

## Usage
/build-gold-models `$ARGUMENTS

Where `$ARGUMENTS is the path to the tech spec file.

## Pre-Flight
Load and follow these skills before starting:
- skills/dbt-implementation-validator
- skills/dbt-best-practices

## Important
Start a fresh Claude Code instance (or /clear) before running this command.
Do not carry bronze/silver context into the gold build.

## Steps

1. **Read the tech spec**
   - Open `$ARGUMENTS and locate the Gold Models section
   - Create a to-do list of every gold model to build
   - Note dependencies on silver models

2. **Verify silver models exist**
   - Run: dbt ls --select tag:silver
   - Confirm all silver models the gold layer depends on are built

3. **Build each gold model**
   For every gold model in the to-do list:
   - Create the .sql file in models/gold/
   - Reference silver models using ref()
   - Apply business metrics and aggregations
   - Document all columns in schema.yml

4. **Validate**
   - Run: dbt build --select tag:gold
   - If tests fail: query data with dbt show, fix, rerun
   - All tests must pass

5. **Verify analysis output**
   - Use dbt show to query the final gold models
   - Confirm results match what the tech spec intended

6. **Summary**
   Report which models were built and confirm data looks correct.
"@ | Set-Content "$cmd\build-gold-models.md"

# build-silver-models.md
@"
---
description: Build all silver models defined in a tech spec using the dbt MCP server
allowed-tools: Read(*), Edit(*), Bash(dbt*), mcp__dbt__dbt_build, mcp__dbt__dbt_show, mcp__dbt__dbt_test
---

# /build-silver-models

Build all silver layer dbt models from a technical specification.

## Usage
/build-silver-models `$ARGUMENTS

Where `$ARGUMENTS is the path to the tech spec file.

## Pre-Flight
Load and follow these skills before starting:
- skills/dbt-implementation-validator
- skills/dbt-best-practices

## Important
Start a fresh Claude Code instance (or /clear) before running this command.
Do not carry bronze context into the silver build.

## Steps

1. **Read the tech spec**
   - Open `$ARGUMENTS and locate the Silver Models section
   - Also read any Intermediate Models section
   - Create a to-do list in dependency order

2. **Verify bronze models exist**
   - Run: dbt ls --select tag:bronze
   - Confirm all bronze models the silver layer depends on are present

3. **Build intermediate models first** (if any)
   - Create any mapping or intermediate models (e.g. int_role_mapping)
   - These live in models/silver/ with an int_ prefix

4. **Build each silver model**
   For every silver model in the to-do list:
   - Create the .sql file in models/silver/
   - Reference bronze using ref()
   - Apply cleaning, conforming, and joining logic
   - Document all columns in schema.yml

5. **Validate**
   - Run: dbt build --select tag:silver
   - If tests fail: use dbt show to query data, fix, rerun
   - All tests must pass

6. **Summary**
   Report which models were built and any mapping decisions made.
"@ | Set-Content "$cmd\build-silver-models.md"

# build.md
@"
---
description: Run dbt build on a specific model or selector
allowed-tools: Bash(dbt build*), mcp__dbt__dbt_build
---

# /build

Run dbt build on a specified model, tag, or selector.

## Usage
/build `$ARGUMENTS

Examples:
- /build bronze_deals
- /build tag:bronze
- /build tag:silver --exclude int_role_mapping
- /build +gold_hiring_gap  (build model and all upstream dependencies)

## Steps

1. Run: ``dbt build --select `$ARGUMENTS``

2. Parse the output:
   - Show which models ran
   - Show which tests passed or failed
   - Highlight any errors with the exact message

3. If tests fail:
   - Identify which test failed and on which model
   - Use dbt show to query the affected data
   - Suggest a fix but do NOT auto-apply without confirmation

4. Report final status: PASS or FAIL with summary counts.
"@ | Set-Content "$cmd\build.md"

# chore_plan.md
@"
---
description: Plan and execute routine maintenance tasks on the dbt project
allowed-tools: Read(*), Bash(dbt*), Bash(git*), mcp__dbt__dbt_build, mcp__dbt__dbt_ls
---

# /chore-plan

Identify and plan routine maintenance tasks for the dbt project.
Use this command to keep the codebase clean and up to date.

## Usage
/chore-plan `$ARGUMENTS

Where `$ARGUMENTS optionally specifies a focus area:
- "docs" — find undocumented models
- "tests" — find models missing tests
- "deps" — check for outdated packages
- "style" — run SQLFluff linting
- (empty) — run all checks

## Steps

1. **Documentation audit**
   - Run: dbt ls --select *
   - Find models with missing or placeholder descriptions in schema.yml
   - List them with file paths

2. **Test coverage audit**
   - Find models with no tests defined in schema.yml
   - Prioritize gold and silver models
   - List gaps

3. **Package freshness**
   - Read packages.yml
   - Check dbt Hub for newer versions of each package
   - Flag any outdated dependencies

4. **SQL style check**
   - Run: sqlfluff lint models/ --dialect snowflake
   - Summarize violations by rule

5. **Produce chore list**
   Output a prioritized markdown checklist of all findings.
   Ask which items to tackle before making any changes.
"@ | Set-Content "$cmd\chore_plan.md"

# clock-out.md
@"
---
description: End a work session cleanly - save context, commit WIP, and write a handoff note
allowed-tools: Read(*), Edit(*), Bash(git*)
---

# /clock-out

End a Claude Code session cleanly. Saves context, commits any
work-in-progress, and writes a handoff note for the next session.

## Steps

1. **Check git status**
   - Run: ``git status``
   - List all uncommitted changes

2. **Commit work in progress** (if any)
   - Stage all changes: ``git add -A``
   - Commit with WIP message: ``git commit -m "WIP: [brief description of where things stand]"``

3. **Write handoff note**
   Create or update ``plans/handoff.md`` with:
   - What was completed this session
   - What is in progress (WIP commit details)
   - What comes next (next steps in order)
   - Any blockers or decisions needed
   - Which tech spec section is currently being worked on

4. **Save context summary**
   Append to ``plans/session-log.md``:
   - Date and time
   - Models built or changed
   - Tests status
   - Decisions made

5. **Confirm**
   Print: "Session saved. Handoff note written to plans/handoff.md"
"@ | Set-Content "$cmd\clock-out.md"

# git-commit-all.md
@"
---
description: Stage and commit all current changes with a descriptive commit message
allowed-tools: Bash(git*)
---

# /git-commit-all

Stage all current changes and create a well-formatted git commit.

## Usage
/git-commit-all `$ARGUMENTS

Where `$ARGUMENTS is an optional commit message.
If not provided, Claude will generate one from the changes.

## Steps

1. **Review changes**
   - Run: ``git status``
   - Run: ``git diff --stat``
   - Understand what files changed and why

2. **Generate commit message** (if not provided)
   Based on the changes, write a commit message following this format:
   ``````
   [type]: brief description (max 72 chars)

   - Detail 1
   - Detail 2
   ``````
   Types: feat, fix, docs, style, refactor, test, chore

3. **Stage and commit**
   - Run: ``git add -A``
   - Run: ``git commit -m "[generated or provided message]"``

4. **Confirm**
   Show the commit hash and message.
"@ | Set-Content "$cmd\git-commit-all.md"

# git-commit.md
@"
---
description: Create a git commit for specific files with a descriptive message
allowed-tools: Bash(git*)
---

# /git-commit

Stage specific files and create a git commit.

## Usage
/git-commit `$ARGUMENTS

Where `$ARGUMENTS is a file path, glob, or commit description.

## Steps

1. **Review what will be committed**
   - Run: ``git status``
   - If `$ARGUMENTS is a path: ``git diff `$ARGUMENTS``

2. **Stage the specified files**
   - Run: ``git add `$ARGUMENTS``
   - Or if no files specified: ``git add -A``

3. **Write commit message**
   Based on the staged changes, write:
   ``````
   [type]: brief description

   Models changed: model_a, model_b
   Tests: all passing
   ``````

4. **Commit**
   - Run: ``git commit -m "[message]"``

5. **Confirm**
   Show commit hash and files committed.
"@ | Set-Content "$cmd\git-commit.md"

# git-create-branch.md — PATCHED: backtick-escaped $ARGUMENTS to avoid PS drive error
@"
---
description: Create a new git branch following Mammoth naming conventions
allowed-tools: Bash(git*)
---

# /git-create-branch

Create a new feature branch following Mammoth Growth naming conventions.

## Usage
/git-create-branch `$ARGUMENTS

Where `$ARGUMENTS is the use case or feature name.
Example: /git-create-branch forecasting-model

## Naming Convention
Mammoth branch names follow this format:
``
initials/use-case-name
``
Example: dc/forecasting-model

## Steps

1. **Determine branch name**
   - Read CLAUDE.md for the engineer's initials (or ask if not set)
   - Combine with the argument provided: initials/your-feature-name
   - Replace spaces with hyphens, lowercase everything

2. **Check current branch**
   - Run: git branch --show-current
   - If not on main/master, confirm before branching

3. **Pull latest**
   - Run: git pull origin main

4. **Create branch**
   - Run: git checkout -b initials/your-feature-name

5. **Confirm**
   Print the new branch name that was created.
"@ | Set-Content "$cmd\git-create-branch.md"

# github-create-pr.md
@"
---
description: Create a GitHub pull request with full Mammoth Growth PR template
allowed-tools: Bash(git*), Bash(gh*)
---

# /github-create-pr

Push the current branch and create a GitHub PR using the Mammoth Growth PR template.

## Usage
/github-create-pr `$ARGUMENTS

Where `$ARGUMENTS is an optional PR title override.

## Pre-Requisites
- GitHub CLI (gh) must be installed and authenticated
- All changes must be committed
- Branch must be pushed to remote

## Steps

1. **Verify clean state**
   - Run: ``git status``
   - If uncommitted changes exist, run /git-commit-all first

2. **Push branch**
   - Run: ``git push origin `$(git branch --show-current)``

3. **Gather PR content**
   Read the following to build the PR body:
   - The tech spec (`$ARGUMENTS or most recently used spec)
   - Git log since branching from main: ``git log main..HEAD --oneline``
   - List of files changed: ``git diff --name-only main``

4. **Create PR using template**
   Fill in .claude/templates/pr-template.md with:
   - Requirements addressed (from tech spec)
   - Models built (from git diff)
   - Tests run and status (from last dbt build output)
   - Due diligence checklist (all items checked)

5. **Submit PR**
   - Run: ``gh pr create --title "[title]" --body "[filled template]"``

6. **Confirm**
   Print the PR URL.
"@ | Set-Content "$cmd\github-create-pr.md"

# load_ai_docs.md — PATCHED: backtick-escaped $ARGUMENTS, removed ambiguous colon references
@"
---
description: Load relevant AI documentation files into context for a specific task
allowed-tools: Read(*)
---

# /load-ai-docs

Load the relevant documentation from .claude/ai_docs/external/ into context
before starting a build or research task.

## Usage
/load-ai-docs `$ARGUMENTS

Where `$ARGUMENTS specifies what to load:
- "claude" — load all Claude Code docs
- "dbt" — load all dbt semantic layer docs
- "semantic" — load semantic model and metrics docs
- "all" — load everything
- (specific topic) — e.g. "hooks", "mcp", "metrics"

## Steps

1. **Determine what to load** based on the argument provided:

   If "claude" or "all":
   - Read ai_docs/external/claude-code-common-workflows.md
   - Read ai_docs/external/claude-code-hooks.md
   - Read ai_docs/external/claude-code-mcp.md
   - Read ai_docs/external/claude-code-slash-commands.md
   - Read ai_docs/external/claude-code-sub-agents.md
   - Read ai_docs/external/claude-code-settings.md
   - Read ai_docs/external/claude-models-overview.md

   If "dbt" or "semantic" or "all":
   - Read ai_docs/external/dbt-semantic-models.md
   - Read ai_docs/external/dbt-metrics-overview.md
   - Read ai_docs/external/dbt-entities.md
   - Read ai_docs/external/dbt-measures.md
   - Read ai_docs/external/dbt-dimensions.md

   If specific topic (e.g. "hooks"):
   - Search for the matching file and read it

2. **Confirm** what was loaded:
   Print: "Loaded: [list of files read]"
   Print: "Ready for: [what these docs enable]"
"@ | Set-Content "$cmd\load_ai_docs.md"

# metaprompt_workflow.md
@"
---
description: Generate an optimized prompt for a complex agentic task using meta-prompting
allowed-tools: Read(*)
---

# /metaprompt-workflow

Use meta-prompting to generate the best possible prompt for a complex task
before executing it. This improves agent output quality on ambiguous or
high-stakes tasks.

## Usage
/metaprompt-workflow `$ARGUMENTS

Where `$ARGUMENTS describes the task you want to accomplish.

## When to Use This
Use this command when:
- The task is complex or ambiguous
- A poor prompt would waste significant compute
- You want to validate your approach before a long agentic run
- You are designing a new skill or command

## Steps

1. **Analyze the task**
   Given: `$ARGUMENTS
   Identify:
   - What is the desired output?
   - What context is needed?
   - What skills/tools are required?
   - What are the failure modes?

2. **Generate optimized prompt**
   Write a prompt that:
   - Has a clear role definition ("You are a Mammoth Growth analytics engineer...")
   - Specifies exact steps in order
   - Includes validation criteria
   - References the correct skills and tools
   - Handles edge cases explicitly

3. **Review and refine**
   - Show the generated prompt
   - Explain why each section is worded that way
   - Ask for approval before executing

4. **Execute** (if approved)
   Run the optimized prompt as the actual task.
"@ | Set-Content "$cmd\metaprompt_workflow.md"

# profile_column_relationship.md
@"
---
description: Profile the relationship between two columns to understand join quality
allowed-tools: mcp__dbt__dbt_show, Bash(dbt*)
---

# /profile-column-relationship

Analyze the relationship between two columns, typically to validate a join
or understand foreign key quality before building a silver model.

## Usage
/profile-column-relationship `$ARGUMENTS

Where `$ARGUMENTS is: table1.column1 table2.column2
Example: /profile-column-relationship bronze_deals.client_id bronze_clients.client_id

## Steps

1. **Parse the arguments**
   Extract: table1, column1, table2, column2

2. **Profile left side**
   Using dbt show, query:
   - Total rows in table1
   - Distinct values of column1
   - Null count in column1
   - Sample values

3. **Profile right side**
   Using dbt show, query:
   - Total rows in table2
   - Distinct values of column2
   - Null count in column2
   - Sample values

4. **Join analysis**
   - Count how many table1.column1 values exist in table2.column2 (match rate)
   - Count orphaned records (in table1 but not table2)
   - Count unmatched records (in table2 but not table1)
   - Identify if this is a 1:1, 1:many, or many:many relationship

5. **Report**
   Output:
   ``````
   COLUMN RELATIONSHIP PROFILE
   Left:  table1.column1 -- X rows, Y distinct, Z nulls
   Right: table2.column2 -- X rows, Y distinct, Z nulls

   Match rate:     XX%
   Orphaned left:  X rows
   Relationship:   1:many

   RECOMMENDATION: [safe to join / investigate orphans / do not join]
   ``````
"@ | Set-Content "$cmd\profile_column_relationship.md"

# profile_column.md
@"
---
description: Profile a single column to understand its data quality and distribution
allowed-tools: mcp__dbt__dbt_show, Bash(dbt*)
---

# /profile-column

Profile a single column to understand nulls, distinct values, distribution,
and data quality before building models that depend on it.

## Usage
/profile-column `$ARGUMENTS

Where `$ARGUMENTS is: table_name.column_name
Example: /profile-column bronze_deals.deal_stage

## Steps

1. **Parse arguments**
   Extract table name and column name from `$ARGUMENTS

2. **Basic stats**
   Using dbt show, query:
   - Total row count
   - Null count and null percentage
   - Distinct value count

3. **Distribution** (choose based on column type)

   For categorical columns:
   - Top 20 values with count and percentage
   - Flag values that may need standardization

   For numeric columns:
   - Min, max, average, median
   - Count of zeros
   - Count of negatives (if unexpected)

   For date columns:
   - Min date, max date, date range
   - Count of future dates (if suspicious)
   - Count of dates before 2000 (if suspicious)

4. **Data quality flags**
   Automatically flag:
   - Null rate > 10% (warning)
   - Null rate > 50% (critical)
   - Single value dominates > 90% (possible bad data)
   - Values that look like test data ("test", "NULL", "n/a", "0000")

5. **Report**
   Output a clean summary with recommendations for testing strategy.
"@ | Set-Content "$cmd\profile_column.md"

# profile_domain.md
@"
---
description: Profile all distinct values in a categorical column to define accepted_values tests
allowed-tools: mcp__dbt__dbt_show, Bash(dbt*)
---

# /profile-domain

Profile all distinct values of a categorical column to determine the correct
accepted_values test configuration for schema.yml.

## Usage
/profile-domain `$ARGUMENTS

Where `$ARGUMENTS is: table_name.column_name
Example: /profile-domain bronze_deal_resources.role_raw

## Steps

1. **Query all distinct values**
   Using dbt show:
   ``````sql
   SELECT DISTINCT column_name, COUNT(*) as row_count
   FROM table_name
   GROUP BY 1
   ORDER BY 2 DESC
   ``````

2. **Analyze**
   - How many distinct values are there?
   - Are there variations of the same value? (e.g. "AE", "Analytics Engineer", "Analytics Eng")
   - Are there nulls?
   - Are there suspicious values? ("test", "unknown", "n/a", "other")

3. **Suggest standardization** (if needed)
   If values are messy, propose a mapping table for int_role_mapping style intermediate models

4. **Generate test config**
   Output the ready-to-paste accepted_values test for schema.yml:
   ``````yaml
   - name: column_name
     tests:
       - accepted_values:
           values: ['value1', 'value2', 'value3']
   ``````

5. **Suggest mapping** (if standardization is needed)
   Output a ready-to-use CASE statement for the silver model.
"@ | Set-Content "$cmd\profile_domain.md"

# profile_plan.md
@"
---
description: Create a full data profiling plan for all sources in a tech spec
allowed-tools: Read(*), mcp__dbt__dbt_show, Bash(dbt*)
---

# /profile-plan

Read a tech spec and create a comprehensive data profiling plan covering
all source tables and key columns before building begins.

## Usage
/profile-plan `$ARGUMENTS

Where `$ARGUMENTS is the path to the tech spec file.

## Steps

1. **Read the tech spec**
   - Open `$ARGUMENTS
   - Extract all source tables listed in the Bronze Models section
   - Extract all key columns that have business logic applied in silver/gold

2. **Create profiling to-do list**
   For each source table, plan to profile:
   - Row count
   - All key columns (PKs, FKs, categorical fields, dates)
   - Any columns with business rules in the tech spec

3. **Execute profiles** (table by table)
   Using dbt show via MCP:
   - Run /profile-table for each source table
   - Run /profile-column for each key column
   - Run /profile-domain for each categorical column

4. **Compile findings**
   After all profiles complete, write a summary to plans/data-profile.md:
   - Source table inventory
   - Data quality issues found
   - Columns needing standardization
   - Recommended test configurations
   - Any spec assumptions that need revision

5. **Flag blockers**
   If any source table is missing, empty, or has critical data quality issues --
   stop and report before building begins.
"@ | Set-Content "$cmd\profile_plan.md"

# profile_table_relationships.md
@"
---
description: Profile all foreign key relationships between tables in a tech spec
allowed-tools: mcp__dbt__dbt_show, Bash(dbt*), Read(*)
---

# /profile-table-relationships

Profile all join relationships between tables defined in a tech spec
to validate join quality before building silver models.

## Usage
/profile-table-relationships `$ARGUMENTS

Where `$ARGUMENTS is the path to the tech spec file.

## Steps

1. **Read the tech spec**
   - Extract all join relationships defined in the Silver and Gold sections
   - List every pair of tables that will be joined and their join keys

2. **For each join relationship**
   Run /profile-column-relationship on each pair:
   - Source table join key vs target table join key
   - Document match rate, orphans, and relationship cardinality

3. **Compile join quality report**
   Output a table:
   ``````
   | Left Table | Left Key | Right Table | Right Key | Match Rate | Cardinality | Issues |
   |-----------|---------|------------|---------|-----------|-------------|--------|
   ``````

4. **Flag bad joins**
   Warn if any join has:
   - Match rate < 80% (warning)
   - Match rate < 50% (critical -- stop and investigate)
   - Many:many relationship (confirm this is intentional)

5. **Recommend**
   For each flagged join, suggest:
   - Whether to LEFT JOIN or INNER JOIN
   - Whether to add a relationship test in schema.yml
   - Whether the tech spec needs revision
"@ | Set-Content "$cmd\profile_table_relationships.md"

# profile_table.md
@"
---
description: Profile a complete table to understand its shape, grain, and data quality
allowed-tools: mcp__dbt__dbt_show, Bash(dbt*)
---

# /profile-table

Profile a complete dbt model or source table to understand its shape,
grain, row count, and key column quality.

## Usage
/profile-table `$ARGUMENTS

Where `$ARGUMENTS is the table or model name.
Example: /profile-table bronze_deals
Example: /profile-table raw.crm.deals

## Steps

1. **Basic shape**
   Using dbt show, query:
   - Row count
   - Column count
   - Column names and data types
   - Sample of 5 rows

2. **Grain validation**
   - Find the candidate primary key
   - Check if it is unique: SELECT COUNT(*) vs COUNT(DISTINCT pk_col)
   - Report duplicate rate

3. **Null analysis**
   For every column:
   - Count nulls and null percentage
   - Flag columns with > 10% nulls

4. **Date range** (for any date columns)
   - Min and max date
   - Flag suspicious dates

5. **Key categorical columns**
   For any column that looks categorical (< 50 distinct values):
   - List all distinct values with counts

6. **Report**
   Output a structured profile:
   ``````
   TABLE PROFILE: table_name
   Rows: X | Columns: Y | Grain: column_name (unique: yes/no)

   NULLS:
   column_name: X% null

   CATEGORICALS:
   stage: ['Open', 'Closed', 'Pending']

   SAMPLE:
   [5 row preview]
   ``````
"@ | Set-Content "$cmd\profile_table.md"

# read_conditional_docs.md
@"
---
description: Conditionally load documentation files based on what the current task requires
allowed-tools: Read(*)
---

# /read-conditional-docs

Intelligently determine which documentation files are relevant to the current
task and load only those -- avoiding unnecessary context usage.

## Usage
/read-conditional-docs `$ARGUMENTS

Where `$ARGUMENTS describes what you are about to do.
Example: /read-conditional-docs "build silver models with semantic layer"

## Logic

Analyze `$ARGUMENTS and load docs based on these rules:

| Task mentions | Load these files |
|--------------|-----------------|
| bronze, sources, raw | dbt-best-practices skill, dbt-validation.md |
| silver, intermediate, mapping | dbt-best-practices skill, dbt-join-logic.md |
| gold, metrics, aggregation | dbt-best-practices skill, dbt-metrics-overview.md |
| semantic, semantic model | dbt-semantic-models.md, dbt-entities.md, dbt-measures.md |
| simple metric | dbt-simple-metrics.md |
| ratio metric | dbt-ratio-metrics.md |
| cumulative metric | dbt-cumulative-metrics.md |
| derived metric | dbt-derived-metrics.md |
| fill nulls, timespine | dbt-fill-nulls-advanced.md, metricflow-time-spine.md |
| hooks | claude-code-hooks.md |
| mcp, tools | claude-code-mcp.md |
| sub-agent, subagent | claude-code-sub-agents.md |
| PR, pull request, git | skills/git/skill.md, skills/pr-from-spec/skill.md |
| tech spec, plan | skills/tech-spec-plan/skill.md |

## Steps

1. Parse `$ARGUMENTS for topic keywords
2. Load the matching documentation files
3. Confirm what was loaded and what it enables
4. Proceed with the original task
"@ | Set-Content "$cmd\read_conditional_docs.md"

# save-context.md
@"
---
description: Save current session context and progress to a file for future reference
allowed-tools: Read(*), Edit(*), Bash(git*)
---

# /save-context

Save a snapshot of the current session's progress, decisions, and state
to plans/session-context.md for future sessions or handoffs.

## Usage
/save-context `$ARGUMENTS

Where `$ARGUMENTS is an optional label for this context snapshot.

## Steps

1. **Gather current state**
   - Run: ``git status`` -- what files have changed?
   - Run: ``git log --oneline -10`` -- what was recently committed?
   - Run: ``dbt ls`` -- what models currently exist?

2. **Document progress**
   Write to plans/session-context.md (create if not exists, append if exists):

   ``````markdown
   ## Session: [date/time] -- `$ARGUMENTS

   ### Completed
   - [list models built and committed]

   ### In Progress
   - [current model being worked on]
   - [current state / where things stand]

   ### Next Steps
   - [ordered list of what comes next]

   ### Decisions Made
   - [any non-obvious choices made and why]

   ### Tech Spec Reference
   - File: [path to tech spec]
   - Section: [current section]
   ``````

3. **Confirm**
   Print: "Context saved to plans/session-context.md"
   Print a summary of what was saved.
"@ | Set-Content "$cmd\save-context.md"

# tech_spec_plan.md
@"
---
description: Convert a Business Requirements Document into a full Technical Specification
allowed-tools: Read(*), Edit(*), mcp__dbt__dbt_show
---

# /tech-spec-plan

Transform a Business Requirements Document (BRD) or Business Use Case into
a complete Technical Specification ready for agentic implementation.

## Usage
/tech-spec-plan `$ARGUMENTS

Where `$ARGUMENTS is the path to the BRD or Business Use Case document.

## Load Skill
Read and follow: skills/tech-spec-plan/skill.md

## Steps

1. **Read the BRD**
   - Open `$ARGUMENTS
   - Extract: metrics defined, data sources, grain, business rules

2. **Explore source data**
   For each data source listed:
   - Use dbt show to preview the table
   - Confirm column names and data types
   - Note any data quality issues

3. **Design the Bronze layer**
   For each source table:
   - Define model name (bronze_[source_table])
   - List all columns with source name -> target name mapping
   - Note any JSON flattening needed

4. **Design the Silver layer**
   - Identify any intermediate/mapping models needed
   - For each silver model: define joins, filters, business rules
   - Specify grain for each model

5. **Design the Gold layer**
   - Define final analytical models
   - Specify all metrics with exact SQL logic
   - Define grain and materialization

6. **Write the Tech Spec**
   Save to plans/tech-spec-[use-case].md using the template from:
   .claude/templates/tech-spec-template.md

7. **Validate**
   Run /validate-spec on the output before handing to build commands.
"@ | Set-Content "$cmd\tech_spec_plan.md"

# ─────────────────────────────────────────────
# DONE
# ─────────────────────────────────────────────

$count = (Get-ChildItem "$cmd" -Recurse -File).Count
Write-Host ""
Write-Host "========================================="
Write-Host "Commands folder complete!"
Write-Host "Total files created: $count"
Write-Host ""
Write-Host "SUBFOLDERS:"
Write-Host "  .claude\commands\tusk\   (task/ticket management)"
Write-Host "  .claude\commands\utils\  (utility helpers)"
Write-Host ""
Write-Host "COMMAND FILES (invoke with /command-name):"
Write-Host "  /all-tools               List all MCP tools and commands"
Write-Host "  /bug-plan                Diagnose failing model, create fix plan"
Write-Host "  /build-bronze-models     Build bronze layer from tech spec"
Write-Host "  /build-full-spec         Build all layers end-to-end"
Write-Host "  /build-gold-models       Build gold layer from tech spec"
Write-Host "  /build-silver-models     Build silver layer from tech spec"
Write-Host "  /build                   Run dbt build on a selector"
Write-Host "  /chore-plan              Identify maintenance tasks"
Write-Host "  /clock-out               End session, save context, commit WIP"
Write-Host "  /git-commit-all          Stage and commit all changes"
Write-Host "  /git-commit              Stage and commit specific files"
Write-Host "  /git-create-branch       Create branch with Mammoth naming"
Write-Host "  /github-create-pr        Create GitHub PR with Mammoth template"
Write-Host "  /load-ai-docs            Load relevant docs into context"
Write-Host "  /metaprompt-workflow     Generate optimized prompt before executing"
Write-Host "  /profile-column-relationship  Profile join quality between columns"
Write-Host "  /profile-column          Profile a single column"
Write-Host "  /profile-domain          Profile categorical values for tests"
Write-Host "  /profile-plan            Full profiling plan from tech spec"
Write-Host "  /profile-table-relationships  Profile all joins in a tech spec"
Write-Host "  /profile-table           Profile a complete table"
Write-Host "  /read-conditional-docs   Load only docs relevant to current task"
Write-Host "  /save-context            Save session progress to file"
Write-Host "  /tech-spec-plan          Convert BRD into full tech spec"
Write-Host "========================================="
