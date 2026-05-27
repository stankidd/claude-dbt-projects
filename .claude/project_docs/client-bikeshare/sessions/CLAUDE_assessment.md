# Mammoth Growth AI Assessment
# NYC Citi Bike Warehouse Build

## Context
This is the Mammoth Growth AI engineering assessment.
Time budget: 2 hours from when building starts.
Senior data engineer role — judgment over completeness.

## Engineer
Stan Kidd (initials: sk)
Target schema: CANDIDATE_TEST.CANDIDATE_STAN_KIDD_DEV

## MCP Tools Available
dbt MCP server connected with 47 tools:
- dbt_show: query source data before writing SQL
- dbt_build: compile run and test models
- dbt_test: run tests only
- dbt_ls: list models

## Source Data
Database: CANDIDATE_TEST
Schema: RAW
Tables:
  trips_2023_q1   800K rows  Legacy Citi Bike schema  nanosecond timestamps
  trips_2023_q4   800K rows  Lyft schema              nanosecond timestamps
  stations        2303 rows  Decimal suffix on IDs (e.g. 5506.14)
  station_history 460 rows   HIST_ prefix on previous_station_id
  weather_hourly  8760 rows  NOAA NYC Central Park    nanosecond timestamps
  bike_inventory  15600 rows Fleet lifecycle events

## CRITICAL: Timestamp Conversion
ALL timestamps are nanosecond Unix integers. Convert with:
TO_TIMESTAMP_NTZ(CAST(col AS NUMBER) / 1000000 / 1000)

## CRITICAL: Q1 Column Names Have Spaces
Quote them in SQL:
"start station id"         AS start_station_id
"start station name"       AS start_station_name
"start station latitude"   AS start_lat
"start station longitude"  AS start_lng
"end station id"           AS end_station_id
"end station name"         AS end_station_name
"end station latitude"     AS end_lat
"end station longitude"    AS end_lng

## CRITICAL: Station ID Decimal Suffixes
Strip for joining: SPLIT_PART(station_id, '.', 1)

## CRITICAL: Q1 vs Q4 Schema Differences
Q1 usertype:     'Subscriber' or 'Customer'
Q4 member_casual: 'member' or 'casual'
Normalize to is_member boolean in silver_trips.

Q1 has no ride_id - generate with ROW_NUMBER()
Q4 has ride_id - use directly as trip_id

Q1 rideable_type: hardcode 'classic_bike' (predates e-bikes)
Q4 rideable_type: use actual field value

## Layer Rules
Bronze: parse and rename ONLY. No business logic. No joins. No filters.
Silver: union Q1+Q4, resolve stations, convert timestamps, derive flags.
Gold: business metrics and novel insight.

## Model Folder Structure
models/bronze/   <- flat, no subfolders
models/silver/   <- flat, no subfolders
models/gold/     <- flat, no subfolders

## Novel Insight Plan
gold_station_performance classifies stations as Commuter vs Leisure:
- Commuter: weekday_weekend_ratio > 1.5 AND peak_hour_pct > 0.25
- Seasonal stability: Q1 vs Q4 variance < 20%
This identifies B2B employer subsidy program expansion targets.

## Tech Spec Location
.claude/project_docs/client-bikeshare/04-specs/documents/bikeshare-tech-spec.md
Read this before starting any build command.

## On Every Task
1. Use dbt_show to query source data before writing any SQL
2. Follow all rules above - especially timestamp conversion
3. Run dbt_build to validate after each model
4. Never push code with failing tests

## Required Deliverables
- dbt project: bronze/silver/gold all building and tested
- README_SOLUTION.md: architecture, cuts, next steps
- insight/commuter_station_analysis.sql: novel insight SQL
- insight/commuter_station_findings.md: results and interpretation
- RETROSPECTIVE.md: ~100 words on AI help and hindrance
- .claude/ committed to repo

## Time Budget Guidance
0:00-0:15  Profile tables and confirm spec against actual data
0:15-0:45  Build bronze layer (6 models)
0:45-1:15  Build silver layer (4 models)
1:15-1:35  Build gold layer (3 models) + run insight query
1:35-1:50  Write README_SOLUTION.md and RETROSPECTIVE.md
1:50-2:00  Push PR and email Dylan

## Submission
Push to private GitHub repo
Add @mammothgrowth-recruiting as collaborator
Email PR link to dylan.cruise@mammothgrowth.com