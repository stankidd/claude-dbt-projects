# Bike-Share Operator — Technical Specification

**Client:** Bike-Share Operator (NYC)
**BRD:** .claude/project_docs/client-bikeshare/03-requirements/bikeshare-brd.md
**Author:** Stan Kidd, Mammoth Growth
**Date:** May 2026
**Status:** Ready to Build
**Time Budget:** 2 hours
**Target Schema:** CANDIDATE_TEST.CANDIDATE_STAN_KIDD_DEV

---

## Architecture Overview

```
CANDIDATE_TEST.RAW
  trips_2023_q1  trips_2023_q4  stations  station_history  weather_hourly  bike_inventory
        |               |            |            |               |                |
        v               v            v            v               v                v
   [Bronze Layer — parse, rename, cast types. No business logic.]
        |               |            |            |               |                |
        v               v            v            v               v                v
   bronze_trips_q1  bronze_trips_q4  bronze_stations  bronze_station_history
   bronze_weather_hourly  bronze_bike_inventory
        |                    |              |                |
        v                    v              v                v
   [Silver Layer — union schemas, resolve stations, convert timestamps, join weather]
        |
        v
   silver_trips  silver_stations  silver_weather  silver_bike_fleet
        |               |               |                |
        v               v               v                v
   [Gold Layer — business metrics, station classification, novel insight]
        |
        v
   gold_station_performance  gold_weather_impact  gold_fleet_health
```

---

## CRITICAL: Timestamp Conversion

ALL timestamps in trips and weather are nanosecond Unix integers.
Convert using this pattern in every bronze model:

```sql
TO_TIMESTAMP_NTZ(CAST(starttime AS NUMBER) / 1000000 / 1000) AS started_at
```

---

## CRITICAL: Column Names With Spaces (Q1 Only)

Q1 source columns have spaces — quote them in SQL:

```sql
"start station id"          AS start_station_id
"start station name"        AS start_station_name
"start station latitude"    AS start_lat
"start station longitude"   AS start_lng
"end station id"            AS end_station_id
"end station name"          AS end_station_name
"end station latitude"      AS end_lat
"end station longitude"     AS end_lng
```

---

## Bronze Models

### bronze_trips_q1
- **Source:** source('raw', 'trips_2023_q1')
- **Materialization:** view
- **Grain:** one row per Q1 trip
- **Purpose:** rename columns, convert timestamps, NO business logic

| Target Column | Source Column | Type | Notes |
|--------------|--------------|------|-------|
| trip_id | ROW_NUMBER() OVER (ORDER BY starttime) | varchar | No natural key in Q1 |
| started_at | starttime | timestamp_ntz | Divide by 1e9: CAST(starttime AS NUMBER)/1000000/1000 |
| ended_at | stoptime | timestamp_ntz | Same conversion |
| trip_duration_seconds | tripduration | integer | Pre-calculated in source |
| start_station_id | "start station id" | varchar | Quote due to spaces |
| start_station_name | "start station name" | varchar | Quote due to spaces |
| start_lat | "start station latitude" | float | Quote due to spaces |
| start_lng | "start station longitude" | float | Quote due to spaces |
| end_station_id | "end station id" | varchar | Quote due to spaces |
| end_station_name | "end station name" | varchar | Quote due to spaces |
| end_lat | "end station latitude" | float | Quote due to spaces |
| end_lng | "end station longitude" | float | Quote due to spaces |
| bike_id | bikeid | varchar | |
| user_type | usertype | varchar | 'Subscriber' or 'Customer' |
| rideable_type | 'classic_bike' | varchar | Hardcode — Q1 predates e-bikes |
| quarter | 'Q1' | varchar | Hardcode for seasonal analysis |

**Tests:**
- started_at: not_null
- end_station_id: not_null
- start_station_id: not_null

---

### bronze_trips_q4
- **Source:** source('raw', 'trips_2023_q4')
- **Materialization:** view
- **Grain:** one row per Q4 trip
- **Purpose:** rename columns, convert timestamps, NO business logic

| Target Column | Source Column | Type | Notes |
|--------------|--------------|------|-------|
| trip_id | ride_id | varchar | Natural key exists in Q4 |
| started_at | started_at | timestamp_ntz | CAST(started_at AS NUMBER)/1000000/1000 |
| ended_at | ended_at | timestamp_ntz | Same conversion |
| trip_duration_seconds | DATEDIFF('second', started_at, ended_at) | integer | Derive from timestamps |
| start_station_id | start_station_id | varchar | |
| start_station_name | start_station_name | varchar | |
| start_lat | start_lat | float | |
| start_lng | start_lng | float | |
| end_station_id | end_station_id | varchar | |
| end_station_name | end_station_name | varchar | |
| end_lat | end_lat | float | |
| end_lng | end_lng | float | |
| bike_id | bike_id | varchar | |
| user_type | member_casual | varchar | 'member' or 'casual' |
| rideable_type | rideable_type | varchar | 'electric_bike' or 'classic_bike' |
| quarter | 'Q4' | varchar | Hardcode |

**Tests:**
- trip_id: unique, not_null
- started_at: not_null
- start_station_id: not_null

---

### bronze_stations
- **Source:** source('raw', 'stations')
- **Materialization:** view
- **Grain:** one row per current station

| Target Column | Source Column | Type | Notes |
|--------------|--------------|------|-------|
| station_id | station_id | varchar | Has decimal suffix e.g. 5506.14 |
| station_id_int | SPLIT_PART(station_id, '.', 1) | varchar | Strip decimal for joining to trips |
| station_name | station_name | varchar | |
| lat | lat | float | |
| lng | lng | float | |
| capacity | capacity | integer | |

**Tests:**
- station_id: unique, not_null
- capacity: not_null

---

### bronze_station_history
- **Source:** source('raw', 'station_history')
- **Materialization:** view
- **Grain:** one row per historical station mapping

| Target Column | Source Column | Type | Notes |
|--------------|--------------|------|-------|
| previous_station_id | previous_station_id | varchar | Has HIST_ prefix |
| previous_station_id_clean | REPLACE(previous_station_id, 'HIST_', '') | varchar | Strip HIST_ prefix |
| current_station_id | current_station_id | varchar | Has decimal suffix |
| current_station_id_int | SPLIT_PART(current_station_id, '.', 1) | varchar | Strip decimal |
| station_name | station_name | varchar | |
| lat | lat | float | |
| lng | lng | float | |
| retired_at | retired_at | date | |

**Tests:**
- previous_station_id: not_null
- current_station_id: not_null

---

### bronze_weather_hourly
- **Source:** source('raw', 'weather_hourly')
- **Materialization:** view
- **Grain:** one row per hour of weather observation

| Target Column | Source Column | Type | Notes |
|--------------|--------------|------|-------|
| observed_at | observed_at_utc | timestamp_ntz | CAST(observed_at_utc AS NUMBER)/1000000/1000 |
| observed_hour | DATE_TRUNC('hour', observed_at) | timestamp_ntz | For joining to trips |
| temp_celsius | temp | float | Already in Celsius |
| dewpoint | dwpt | float | |
| humidity_pct | rhum | float | Relative humidity % |
| precipitation_mm | prcp | float | mm of precipitation |
| snow_mm | snow | float | mm of snow |
| wind_dir | wdir | float | degrees |
| wind_speed_kmh | wspd | float | km/h |
| pressure_hpa | pres | float | |
| condition_code | coco | integer | NOAA condition code |

**Tests:**
- observed_at: unique, not_null

---

### bronze_bike_inventory
- **Source:** source('raw', 'bike_inventory')
- **Materialization:** view
- **Grain:** one row per fleet lifecycle event

| Target Column | Source Column | Type | Notes |
|--------------|--------------|------|-------|
| bike_id | bike_id | varchar | |
| event_type | event_type | varchar | 'added' or 'retired' |
| event_date | event_date | date | |
| notes | notes | varchar | |

**Tests:**
- bike_id: not_null
- event_type: accepted_values(['added', 'retired'])

---

## Silver Models

### silver_trips
- **Depends on:** bronze_trips_q1, bronze_trips_q4
- **Materialization:** table
- **Grain:** one row per trip (Q1 + Q4 unioned)
- **Purpose:** Unified schema across both quarters with business logic applied

**Key transformations:**
- UNION ALL of bronze_trips_q1 and bronze_trips_q4
- Normalize user_type: 'Subscriber' OR 'member' → is_member = TRUE
- Filter invalid trips: trip_duration_seconds BETWEEN 60 AND 86400
- Derive trip date parts for analysis
- Strip decimal from station IDs for joining

| Column | Type | Logic |
|--------|------|-------|
| trip_id | varchar | from bronze |
| started_at | timestamp_ntz | from bronze |
| ended_at | timestamp_ntz | from bronze |
| trip_date | date | DATE(started_at) |
| trip_hour | integer | HOUR(started_at) |
| trip_dow | integer | DAYOFWEEK(started_at) 0=Sun 6=Sat |
| is_weekday | boolean | trip_dow NOT IN (0, 6) |
| is_weekend | boolean | trip_dow IN (0, 6) |
| is_am_peak | boolean | trip_hour BETWEEN 7 AND 9 |
| is_pm_peak | boolean | trip_hour BETWEEN 17 AND 19 |
| trip_duration_seconds | integer | from bronze |
| trip_duration_minutes | float | trip_duration_seconds / 60.0 |
| start_station_id | varchar | from bronze |
| start_station_id_int | varchar | SPLIT_PART(start_station_id, '.', 1) |
| end_station_id | varchar | from bronze |
| end_station_id_int | varchar | SPLIT_PART(end_station_id, '.', 1) |
| start_station_name | varchar | from bronze |
| end_station_name | varchar | from bronze |
| start_lat | float | from bronze |
| start_lng | float | from bronze |
| bike_id | varchar | from bronze |
| user_type | varchar | from bronze |
| is_member | boolean | user_type IN ('Subscriber','member') |
| rideable_type | varchar | from bronze |
| quarter | varchar | 'Q1' or 'Q4' |

**Tests:**
- trip_id: unique, not_null
- started_at: not_null
- is_member: not_null
- quarter: accepted_values(['Q1', 'Q4'])

---

### silver_stations
- **Depends on:** bronze_stations, bronze_station_history
- **Materialization:** table
- **Grain:** one row per station (current + resolved history)
- **Purpose:** Unified station reference resolving decimal IDs

| Column | Type | Logic |
|--------|------|-------|
| station_id | varchar | from bronze_stations |
| station_id_int | varchar | SPLIT_PART(station_id, '.', 1) |
| station_name | varchar | from bronze_stations |
| lat | float | from bronze_stations |
| lng | lng | from bronze_stations |
| capacity | integer | from bronze_stations |
| has_history | boolean | TRUE if station_id exists in station_history |

**Tests:**
- station_id: unique, not_null
- station_id_int: not_null

---

### silver_weather
- **Depends on:** bronze_weather_hourly
- **Materialization:** table
- **Grain:** one row per hour
- **Purpose:** Clean weather with derived condition flags for joining to trips

| Column | Type | Logic |
|--------|------|-------|
| observed_at | timestamp_ntz | from bronze |
| observed_hour | timestamp_ntz | from bronze |
| temp_celsius | float | from bronze |
| precipitation_mm | float | COALESCE(precipitation_mm, 0) |
| snow_mm | float | COALESCE(snow_mm, 0) |
| humidity_pct | float | from bronze |
| wind_speed_kmh | float | from bronze |
| condition_code | integer | from bronze |
| is_raining | boolean | precipitation_mm > 0.1 |
| is_snowing | boolean | snow_mm > 0 |
| is_cold | boolean | temp_celsius < 5 |
| is_mild | boolean | temp_celsius BETWEEN 10 AND 25 AND NOT is_raining |
| weather_category | varchar | CASE: 'Rainy', 'Snowy', 'Cold/Dry', 'Mild/Clear', 'Hot' |

**Tests:**
- observed_at: unique, not_null
- is_raining: not_null

---

### silver_bike_fleet
- **Depends on:** bronze_bike_inventory
- **Materialization:** table
- **Grain:** one row per bike (current status)
- **Purpose:** Derive current fleet status from lifecycle events

| Column | Type | Logic |
|--------|------|-------|
| bike_id | varchar | from bronze |
| first_added_date | date | MIN(event_date) WHERE event_type = 'added' |
| retired_date | date | MAX(event_date) WHERE event_type = 'retired' (null if active) |
| is_active | boolean | retired_date IS NULL |
| fleet_age_days | integer | DATEDIFF('day', first_added_date, CURRENT_DATE) |
| fleet_age_years | float | fleet_age_days / 365.0 |

**Tests:**
- bike_id: unique, not_null
- is_active: not_null

---

## Gold Models

### gold_station_performance
- **Depends on:** silver_trips, silver_stations
- **Materialization:** table
- **Grain:** one row per station
- **Purpose:** Station-level trip patterns and commuter classification

**This is the primary novel insight model.**

| Column | Type | Logic |
|--------|------|-------|
| station_id_int | varchar | join key |
| station_name | varchar | from silver_stations |
| lat | float | from silver_stations |
| lng | float | from silver_stations |
| capacity | integer | from silver_stations |
| total_trips | integer | COUNT trips departing |
| q1_trips | integer | COUNT WHERE quarter = 'Q1' |
| q4_trips | integer | COUNT WHERE quarter = 'Q4' |
| weekday_trips | integer | COUNT WHERE is_weekday = TRUE |
| weekend_trips | integer | COUNT WHERE is_weekend = TRUE |
| am_peak_trips | integer | COUNT WHERE is_am_peak = TRUE |
| pm_peak_trips | integer | COUNT WHERE is_pm_peak = TRUE |
| member_trips | integer | COUNT WHERE is_member = TRUE |
| casual_trips | integer | COUNT WHERE is_member = FALSE |
| weekday_weekend_ratio | float | weekday_trips / NULLIF(weekend_trips, 0) |
| peak_hour_pct | float | (am_peak_trips + pm_peak_trips) / NULLIF(total_trips, 0) |
| member_rate | float | member_trips / NULLIF(total_trips, 0) |
| net_flow | integer | trips_departed - trips_arrived |
| station_type | varchar | CASE WHEN weekday_weekend_ratio > 1.5 AND peak_hour_pct > 0.25 THEN 'Commuter' ELSE 'Leisure' END |
| seasonal_stability | varchar | CASE WHEN ABS(q1_trips - q4_trips) / NULLIF(GREATEST(q1_trips,q4_trips),0) < 0.2 THEN 'Stable' ELSE 'Seasonal' END |

**Tests:**
- station_id_int: unique, not_null
- station_type: accepted_values(['Commuter', 'Leisure'])
- weekday_weekend_ratio: not_null

---

### gold_weather_impact
- **Depends on:** silver_trips, silver_weather
- **Materialization:** table
- **Grain:** one row per hour
- **Purpose:** Trips per hour joined to weather for impact analysis

| Column | Type | Logic |
|--------|------|-------|
| trip_hour | timestamp_ntz | DATE_TRUNC('hour', started_at) |
| trip_date | date | DATE(trip_hour) |
| hour_of_day | integer | HOUR(trip_hour) |
| quarter | varchar | Q1 or Q4 |
| trip_count | integer | COUNT trips in this hour |
| member_trip_count | integer | COUNT member trips |
| temp_celsius | float | from silver_weather |
| precipitation_mm | float | from silver_weather |
| is_raining | boolean | from silver_weather |
| is_cold | boolean | from silver_weather |
| is_mild | boolean | from silver_weather |
| weather_category | varchar | from silver_weather |

**Join:**
```sql
LEFT JOIN silver_weather
    ON DATE_TRUNC('hour', silver_trips.started_at) = silver_weather.observed_hour
```

**Tests:**
- trip_hour: unique, not_null

---

### gold_fleet_health
- **Depends on:** silver_bike_fleet, silver_trips
- **Materialization:** table
- **Grain:** one row per bike
- **Purpose:** Fleet utilization and age analysis

| Column | Type | Logic |
|--------|------|-------|
| bike_id | varchar | from silver_bike_fleet |
| is_active | boolean | from silver_bike_fleet |
| fleet_age_days | integer | from silver_bike_fleet |
| fleet_age_years | float | from silver_bike_fleet |
| total_trips | integer | COUNT trips for this bike_id |
| q1_trips | integer | COUNT Q1 trips |
| q4_trips | integer | COUNT Q4 trips |
| trips_per_day | float | total_trips / NULLIF(fleet_age_days, 0) |
| age_category | varchar | CASE: 'New (<1yr)', 'Mid (1-3yr)', 'Aging (3-5yr)', 'Old (5yr+)' |

**Tests:**
- bike_id: unique, not_null
- is_active: not_null

---

## Novel Insight Query

Save to insight/commuter_station_analysis.sql:

```sql
-- Commuter Station Analysis
-- Identifies stations serving B2B employer subsidy program corridors
-- Based on weekday/weekend ratio and AM/PM peak concentration

SELECT
    station_type
    , seasonal_stability
    , COUNT(*) AS station_count
    , ROUND(AVG(total_trips), 0) AS avg_total_trips
    , ROUND(AVG(weekday_weekend_ratio), 2) AS avg_weekday_weekend_ratio
    , ROUND(AVG(peak_hour_pct) * 100, 1) AS avg_peak_hour_pct
    , ROUND(AVG(member_rate) * 100, 1) AS avg_member_rate_pct
FROM gold_station_performance
GROUP BY 1, 2
ORDER BY 1, 2
```

**Expected finding:**
Commuter stations will show higher member rates (annual subscribers = commuters)
and higher Q1/Q4 stability (commuters ride year-round unlike leisure riders).
This makes them ideal anchors for employer subsidy programs.

---

## Sources File

The repo already has sources declared. Verify sources.yml has:

```yaml
version: 2
sources:
  - name: raw
    database: CANDIDATE_TEST
    schema: RAW
    tables:
      - name: trips_2023_q1
      - name: trips_2023_q4
      - name: stations
      - name: station_history
      - name: weather_hourly
      - name: bike_inventory
```

---

## Required Deliverable Files

Create these during the build:

| File | Location | Notes |
|------|----------|-------|
| README_SOLUTION.md | repo root | Architecture, cuts, next steps |
| RETROSPECTIVE.md | repo root | ~100 words on AI help/hindrance |
| insight/commuter_station_analysis.sql | insight/ | Novel insight SQL |
| insight/commuter_station_findings.md | insight/ | Results table and interpretation |

---

## Definition of Done

- [ ] All 6 bronze models build without errors
- [ ] silver_trips successfully unions Q1 + Q4 (verify ~1.6M rows)
- [ ] silver_trips timestamp columns are readable dates (not nanoseconds)
- [ ] All silver models build without errors
- [ ] All gold models build without errors
- [ ] gold_station_performance classifies stations as Commuter or Leisure
- [ ] All dbt tests pass (zero failures)
- [ ] insight/ folder has SQL and findings
- [ ] README_SOLUTION.md written
- [ ] RETROSPECTIVE.md written
- [ ] .claude/ committed to repo
- [ ] PR pushed to private GitHub repo
- [ ] @mammothgrowth-recruiting added as collaborator
- [ ] PR link emailed to dylan.cruise@mammothgrowth.com
