# Solution README - NYC Citi Bike Warehouse

**Candidate:** Stan Kidd
**Date:** [DATE]
**Time Used:** [X] of 120 minutes

---

## Architecture

I built a medallion architecture (Bronze -> Silver -> Gold) on top of
CANDIDATE_TEST.RAW using dbt Core with Claude Code as the agentic harness.

### The Core Challenge: Dual-Schema Trip Data
The most significant architectural decision was handling the schema
incompatibility between Q1 (legacy Citi Bike format) and Q4 (Lyft's
standardized format). Q1 columns contain spaces, lack a natural key,
and use different field names for membership type. Rather than forcing
a join, I kept Q1 and Q4 as separate bronze models and unified them
in the silver layer via a UNION ALL with explicit column mapping.

### Layer Responsibilities

**Bronze (6 models — views)**
Parse and rename only. Each source table gets one bronze model.
Key transformations limited to: renaming columns, converting
nanosecond Unix timestamps to TIMESTAMP_NTZ, stripping decimal
suffixes from station IDs, and removing HIST_ prefixes from
historical station IDs. No business logic.

**Silver (4 models — tables)**
- silver_trips: Unifies Q1 + Q4 into one schema (~1.6M rows).
  Normalizes membership types, derives trip date parts (hour, DOW,
  peak flags), filters invalid trips (< 60s or > 24hrs).
- silver_stations: Resolves station identity using station_history SCD.
- silver_weather: Converts timestamps, fills null precipitation with 0,
  derives weather condition flags (is_raining, is_cold, is_mild).
- silver_bike_fleet: Derives current active/retired status per bike
  from lifecycle event history.

**Gold (3 models — tables)**
- gold_station_performance: Station-level trip patterns and commuter
  classification. The primary novel insight model.
- gold_weather_impact: Hourly trips joined to weather for impact analysis.
- gold_fleet_health: Per-bike utilization and age metrics.

### DAG

`mermaid
graph LR
    Q1[trips_2023_q1] --> BQ1[bronze_trips_q1]
    Q4[trips_2023_q4] --> BQ4[bronze_trips_q4]
    ST[stations] --> BST[bronze_stations]
    SH[station_history] --> BSH[bronze_station_history]
    WX[weather_hourly] --> BWX[bronze_weather_hourly]
    BI[bike_inventory] --> BBI[bronze_bike_inventory]
    BQ1 --> ST[silver_trips]
    BQ4 --> ST
    BST --> SS[silver_stations]
    BSH --> SS
    BWX --> SW[silver_weather]
    BBI --> SBF[silver_bike_fleet]
    ST --> GSP[gold_station_performance]
    SS --> GSP
    ST --> GWI[gold_weather_impact]
    SW --> GWI
    SBF --> GFH[gold_fleet_health]
    ST --> GFH
`

---

## Novel Insight: Commuter Station Classification

See insight/ folder for full SQL and findings.

**The Question:** Which stations serve commuter corridors vs leisure riders?

**The Method:** Classified each station using two signals:
1. Weekday/weekend ratio > 1.5x (commuters ride Mon-Fri)
2. Peak hour concentration > 25% of trips (7-9am + 5-7pm)

**The Finding:** [FILL IN AFTER RUNNING — approx format below]
- ~[N]% of stations ([X] of 2,303) show commuter patterns
- Commuter stations have [X]x higher member rates than leisure stations
- [X]% of commuter stations are seasonally stable (Q1 vs Q4 < 20% variance)
- Seasonally stable commuter stations justify annual B2B contract pricing

**Business Value:** This classification is the analytical foundation for
expanding Citi Bike for Business. Stable commuter stations are natural
anchors for employer subsidy programs and justify annual contract pricing
over quarterly. This analysis did not previously exist in any governed form.

---

## What I Intentionally Cut

Given the 2-hour constraint I prioritized the warehouse foundation and
novel insight over completeness. Intentional cuts:

- **Q2/Q3 data:** Only Q1 and Q4 were provided. The seasonal gap limits
  full-year trend analysis but enables a clean winter vs fall comparison.
- **dbt Semantic Layer / MetricFlow:** The gold models are designed to
  become metric foundations but I did not implement MetricFlow definitions.
  This is the highest-value next step.
- **Route analysis:** Origin-destination pair analysis would add depth
  but required more time than available.
- **Real-time rebalancing model:** Identified as follow-on engagement.

---

## What I Would Do Next

1. **Metric foundations layer** — Define MetricFlow semantic models for
   commuter_utilization, station_type, and member_rate so every downstream
   tool pulls from governed definitions. This is the highest-leverage next
   step for the B2B program.

2. **Full year data** — Add Q2 and Q3 to enable complete seasonal analysis
   and more robust commuter stability scoring.

3. **Predictive rebalancing** — Use weather + commuter pattern data to
   predict hourly demand by station and automate rebalancing dispatch.

4. **B2B pricing model** — Use seasonal stability classification to build
   a tiered pricing model for employer subsidy contracts (annual vs quarterly).

5. **Fleet retirement optimization** — Combine bike age, trip frequency,
   and maintenance events to build a retirement priority score.

---

## AI Tooling

Built using Claude Code (Anthropic) with a dbt MCP server.
See RETROSPECTIVE.md and committed .claude/ folder for details.