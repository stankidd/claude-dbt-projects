# Mammoth Growth DBT Project

## Project Overview
Analytics engineering project following Mammoth Growth standards.
Medallion architecture: Bronze -> Silver -> Gold.

## On Every Task
1. Load the relevant skill from /skills before starting
2. Use the dbt MCP server to query data before assuming anything
3. Follow all rules in skills/dbt-best-practices
4. Run dbt build to validate your work
5. Never push code that has failing tests

## Layer Rules
- **Bronze**: No business logic. Parse raw data only. Materialize as views.
- **Silver**: Clean, conform, join. Materialize as tables.
- **Gold**: Business metrics and aggregations. Materialize as tables.

## SQL Standards
- ALL SQL keywords UPPERCASE
- all field names lowercase_with_underscores
- Always alias tables with meaningful short names
- CTEs preferred over subqueries

## On Completing Any Task
Run /pr-from-spec to push a PR with full context.
