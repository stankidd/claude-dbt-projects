# Retrospective

## AI Tooling Used
Claude Code (Anthropic) with dbt MCP server (47 tools connected).
The MCP server gave Claude direct access to run dbt build, dbt show,
and dbt test autonomously during the build.

## Where AI Helped Most
The dual-schema unification was the hardest part of this assessment.
I described the Q1/Q4 schema mismatch to Claude Code along with the
column mapping table from my tech spec, and it correctly generated the
UNION ALL pattern with explicit aliases on the first attempt. It also
caught that Q1 column names contain spaces requiring double-quoting in
SQL — something easy to miss manually.

The dbt MCP server was the biggest productivity multiplier. Claude ran
dbt show on every source table before writing any SQL, confirming actual
column names matched the spec. When tests failed it queried the data
autonomously to understand why, then fixed and reran — without me
touching the terminal.

## Where AI Struggled
Timestamp conversion required intervention. Claude initially generated
a standard TO_TIMESTAMP conversion that silently produced wrong results
on the nanosecond integers. I caught this during the silver model spot
check and corrected the formula (divide by 1e9 not 1e3).

## What I Would Do Differently
Spend more of the pre-build time writing a tighter CLAUDE.md with
explicit examples of the timestamp conversion and space-in-column-name
patterns. The two places I needed to intervene were both cases where
the source data had unusual formatting that a more detailed CLAUDE.md
would have pre-empted.