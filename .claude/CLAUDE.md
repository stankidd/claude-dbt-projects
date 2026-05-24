# Mammoth Growth DBT Project

## Project Overview
Analytics engineering project using Mammoth Growth agentic dbt workflow.
Medallion architecture: Bronze -> Silver -> Gold.
Warehouse: Snowflake (MAMMOTH_WH / MAMMOTH_DB / MAMMOTH_SCHEMA)
Engineer: Stan Kidd (initials: sk)

## MCP Tools Available
The dbt MCP server is connected with 47 tools including:
- dbt_show: query raw data before building models
- dbt_build: compile, run, and test models
- dbt_test: run tests only
- dbt_ls: list models

## On Every Task
1. Load the relevant skill from .claude/skills/ before starting
2. Use dbt_show via MCP to query source data before writing any SQL
3. Follow all rules in .claude/skills/dbt-best-practices/skill.md
4. Run dbt_build via MCP to validate all models before finishing
5. Never push code that has failing tests

## Layer Rules
- Bronze: No business logic. Parse raw data only. Materialize as views.
- Silver: Clean, conform, join. Apply business rules. Materialize as tables.
- Gold: Business metrics and aggregations. Materialize as tables.

## SQL Standards
- ALL SQL keywords UPPERCASE
- all field names lowercase_with_underscores
- Always alias tables with meaningful short names
- CTEs preferred over subqueries
- Always use ref() to reference other dbt models

## Source Data
For this project we are using Snowflake sample data:
Database: SNOWFLAKE_SAMPLE_DATA
Schema: TPCH_SF1000
Tables: ORDERS, LINEITEM, CUSTOMER, SUPPLIER, PART, PARTSUPP, NATION, REGION

## Git Workflow
- Branch naming: sk/feature-name
- Always run dbt_build before committing
- Use /github-create-pr when work is complete

## On Completing Any Task
Run /github-create-pr to push a PR with full context summary.
