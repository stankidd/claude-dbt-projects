# Mammoth Growth DBT Ops Reporting

## Setup
1. Copy .env.sample to .env and fill in your Snowflake credentials
2. Run: pip install dbt-snowflake
3. Run: dbt deps
4. Open dbt-agentic-demo.code-workspace in VS Code
5. Launch Claude Code

## Agentic Workflow Commands
- /build-bronze-models pointing at your tech spec
- /build-silver-models pointing at your tech spec
- /build-gold-models pointing at your tech spec
- /pr-from-spec to push completed work

## Skills
See .claude/skills/ for all available agent skills.

## New Engineers
See [ONBOARDING.md](ONBOARDING.md) for complete setup instructions.
