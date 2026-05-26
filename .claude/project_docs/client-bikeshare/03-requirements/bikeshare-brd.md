# Bike-Share Operator — Business Requirements Document

**Client:** Bike-Share Operator (NYC)
**Version:** 1.0
**Status:** Approved for Tech Spec
**Prepared by:** Stan Kidd, Mammoth Growth
**Date:** May 2026
**Assessment:** Mammoth Growth AI Engineering Assessment

---

## Business Context

A NYC bike-share operator runs 1.6M+ trips annually across 2,303 active
stations with a 15,600-unit fleet. Raw operational data lives in Snowflake
but has never been transformed into a queryable analytical warehouse. Analysts
currently query raw tables directly with no documentation, no data quality
checks, and no governed metric definitions.

The operator is evaluating a B2B employer subsidy program and needs to
understand which stations serve commuter corridors before pricing that product.

---

## Business Problem

The operator has six source tables but no unified analytical layer:

- Q1 and Q4 trip data use **different schemas** (legacy Citi Bike format vs
  new Lyft format) making direct analysis impossible without transformation
- Timestamps are stored as **nanosecond Unix integers** not human-readable dates
- Station IDs have **decimal suffixes** (e.g. 5506.14) and historical IDs
  have a **HIST_ prefix** making joins unreliable
- No definition exists for what makes a station a "commuter station" vs
  a "leisure station" — critical for B2B program pricing
- Weather impact on ridership is assumed but never quantified

---

## Goals

1. Build a clean, queryable warehouse unifying Q1 and Q4 trip data
   despite their schema differences
2. Resolve station identity across current stations and historical IDs
3. Identify commuter vs leisure stations using trip pattern analysis
4. Quantify weather impact on ridership to support operational planning
5. Provide one novel analytical finding that justifies a follow-on engagement

---

## Decisions This Will Inform

- B2B employer subsidy program station selection and pricing
- Fleet rebalancing strategy during adverse weather
- Bike retirement and fleet refresh prioritization
- Follow-on engagement scope with Mammoth Growth

---

## Metrics Defined

### Trip Metrics
| Metric | Definition | Owner |
|--------|-----------|-------|
| Trip Duration (seconds) | stoptime - starttime (Q1) or ended_at - started_at (Q4) | Ops |
| Trip Duration (minutes) | trip_duration_seconds / 60 | Ops |
| Total Trips | COUNT of trip records | Ops |
| Member Trips | Trips where user_type = 'Subscriber' (Q1) or 'member' (Q4) | Product |
| Casual Trips | Trips where user_type = 'Customer' (Q1) or 'casual' (Q4) | Product |
| Member Rate | Member Trips / Total Trips | Product |

### Station Metrics
| Metric | Definition | Owner |
|--------|-----------|-------|
| Trips Departed | COUNT trips where start_station_id matches | Ops |
| Trips Arrived | COUNT trips where end_station_id matches | Ops |
| Net Flow | Trips Departed - Trips Arrived | Ops |
| Weekday Trip Count | Trips on Mon-Fri | Ops |
| Weekend Trip Count | Trips on Sat-Sun | Ops |
| Weekday/Weekend Ratio | Weekday Trips / Weekend Trips | Ops |
| AM Peak Trips | Trips starting 7am-9am | Ops |
| PM Peak Trips | Trips starting 5pm-7pm | Ops |
| Peak Hour Pct | (AM Peak + PM Peak) / Total Trips | Ops |

### Weather Impact Metrics
| Metric | Definition | Owner |
|--------|-----------|-------|
| Trips Per Hour | COUNT trips in a given hour | Ops |
| Rainy Day Trips | Trips where hourly precipitation > 0.1 | Ops |
| Clear Day Trips | Trips where hourly precipitation = 0 | Ops |
| Cold Hour Trips | Trips where temp < 5 Celsius | Ops |
| Weather Sensitivity | % drop in trips vs clear/mild baseline | Ops |

### Fleet Metrics
| Metric | Definition | Owner |
|--------|-----------|-------|
| Active Bikes | Bikes with event_type = added and no subsequent retired event | Ops |
| Retired Bikes | Bikes with event_type = retired | Ops |
| Fleet Age (days) | Current date - event_date for added bikes | Ops |
| Fleet Utilization | Total Trips / Active Bikes | Ops |

---

## Data Sources

| Source | Table | Rows | Key Challenge |
|--------|-------|------|---------------|
| CANDIDATE_TEST.RAW | trips_2023_q1 | 800,000 | Legacy schema, spaces in col names, nanosecond timestamps, no ride_id |
| CANDIDATE_TEST.RAW | trips_2023_q4 | 800,000 | New schema with rideable_type and member_casual |
| CANDIDATE_TEST.RAW | stations | 2,303 | Station IDs have decimal suffix (e.g. 5506.14) |
| CANDIDATE_TEST.RAW | station_history | 460 | previous_station_id has HIST_ prefix |
| CANDIDATE_TEST.RAW | weather_hourly | 8,760 | Nanosecond timestamps, NOAA condition codes |
| CANDIDATE_TEST.RAW | bike_inventory | 15,600 | Fleet lifecycle events only (added/retired) |

---

## Schema Mapping — Q1 to Q4 Unified Schema

This is the most critical transformation in the project.

| Unified Column | Q1 Source | Q4 Source | Notes |
|---------------|-----------|-----------|-------|
| trip_id | ROW_NUMBER() generated | ride_id | Q1 has no natural key |
| rideable_type | 'classic_bike' (hardcoded) | rideable_type | Q1 predates e-bikes |
| started_at | starttime / 1000000 (ns to ms) | started_at / 1000000 | Convert to timestamp |
| ended_at | stoptime / 1000000 | ended_at / 1000000 | Convert to timestamp |
| trip_duration_seconds | tripduration | DATEDIFF(sec, started_at, ended_at) | Q1 has pre-calc'd value |
| start_station_id | "start station id" (spaces) | start_station_id | Quote in SQL |
| start_station_name | "start station name" | start_station_name | |
| start_lat | "start station latitude" | start_lat | |
| start_lng | "start station longitude" | start_lng | |
| end_station_id | "end station id" | end_station_id | |
| end_station_name | "end station name" | end_station_name | |
| end_lat | "end station latitude" | end_lat | |
| end_lng | "end station longitude" | end_lng | |
| bike_id | bikeid | bike_id | |
| user_type | usertype | member_casual | |
| is_member | usertype = 'Subscriber' | member_casual = 'member' | Normalize to boolean |
| quarter | 'Q1' hardcoded | 'Q4' hardcoded | For seasonal comparison |

---

## Grain Definitions

| Model | Grain |
|-------|-------|
| bronze_trips_q1 | One row per Q1 trip (renamed columns only) |
| bronze_trips_q4 | One row per Q4 trip (renamed columns only) |
| bronze_stations | One row per current station |
| bronze_station_history | One row per historical station mapping |
| bronze_weather_hourly | One row per hour of weather data |
| bronze_bike_inventory | One row per fleet lifecycle event |
| silver_trips | One row per trip (Q1 + Q4 unioned, schema unified) |
| silver_stations | One row per station (history resolved) |
| silver_weather | One row per hour (timestamps converted, condition decoded) |
| silver_bike_fleet | One row per bike (current status derived) |
| gold_station_performance | One row per station (trip patterns + classification) |
| gold_weather_impact | One row per hour (trips joined to weather) |
| gold_fleet_health | One row per bike (utilization and age) |

---

## Business Rules

| Rule | Definition |
|------|-----------|
| Timestamp conversion | Divide nanosecond integer by 1,000,000 then cast to TIMESTAMP_NTZ |
| Station ID join | Strip decimal suffix using SPLIT_PART(station_id, '.', 1) for joining to trips |
| Historical station resolution | Strip HIST_ prefix from previous_station_id |
| Member classification Q1 | usertype = 'Subscriber' → is_member = TRUE |
| Member classification Q4 | member_casual = 'member' → is_member = TRUE |
| Valid trip | trip_duration_seconds BETWEEN 60 AND 86400 (1 min to 24 hours) |
| Peak hour AM | HOUR(started_at) BETWEEN 7 AND 9 |
| Peak hour PM | HOUR(started_at) BETWEEN 17 AND 19 |
| Weekday | DAYOFWEEK(started_at) NOT IN (0, 6) — Mon=1 through Fri=5 |
| Weekend | DAYOFWEEK(started_at) IN (0, 6) |
| Commuter station | weekday_weekend_ratio > 1.5 AND peak_hour_pct > 0.25 |
| Leisure station | All stations not meeting commuter criteria |
| Active bike | Most recent event_type = 'added' |
| Retired bike | Most recent event_type = 'retired' |
| Rainy hour | prcp > 0.1 mm |
| Cold hour | temp < 5 Celsius (41F) |

---

## Novel Insight — Commuter Station Identification

**Finding:** Using Q1 and Q4 trip patterns, identify which stations serve
commuter corridors based on weekday/weekend ratio and AM/PM peak concentration.
Stations with weekday/weekend ratio > 1.5x AND peak hour trips > 25% of daily
trips are classified as commuter anchors.

**Business Value:** These commuter stations are the natural anchor network
for a B2B employer subsidy program. Understanding Q1 vs Q4 seasonal stability
of commuter patterns helps price annual vs quarterly subsidy contracts.

**Framing for follow-on:** This analysis is the first step toward a full
metric foundations layer covering trip profitability, commuter utilization,
and subsidy attribution — exactly what a B2B program requires at scale.

---

## Weather Join Key

Weather data joins to trips on the hour:

```sql
DATE_TRUNC('hour', silver_trips.started_at) =
DATE_TRUNC('hour', silver_weather.observed_at)
```

Weather timestamps also need nanosecond conversion:
```sql
TO_TIMESTAMP_NTZ(observed_at_utc / 1000000 / 1000) AS observed_at
```

---

## Deliverables Required by README

| Deliverable | Description |
|-------------|-------------|
| dbt project | bronze/silver/gold models all building and tested |
| README_SOLUTION.md | Architecture, what was cut, what's next (~1 page) |
| insight/ | Novel insight SQL + output table or chart |
| RETROSPECTIVE.md | ~100 words on AI help/hindrance |
| .claude/ | Full scaffolding committed to repo |

---

## Out of Scope (2-hour constraint)

- dbt Semantic Layer / MetricFlow definitions (Phase 2)
- Predictive rebalancing model
- Real-time or streaming data
- Financial cost allocation or profitability calculations
- Full metric foundations layer (mention in README_SOLUTION as next step)

---

## Success Criteria

- All bronze models build without errors
- silver_trips successfully unions Q1 and Q4 with unified schema
- gold_station_performance classifies stations as commuter vs leisure
- At least one novel insight with supporting SQL in insight/ folder
- All dbt tests pass
- PR pushed and emailed to Dylan within 2-hour window
