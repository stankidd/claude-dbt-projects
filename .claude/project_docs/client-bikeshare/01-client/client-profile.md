# Client Profile - NYC Citi Bike (Operated by Lyft)

## Company Overview
Citi Bike is New York City's official bike-share program, operated by
Lyft since its acquisition in 2018. As of 2023, Citi Bike operates
2,300+ stations across NYC with a mixed fleet of classic and electric
bikes. The program serves both recreational riders and daily commuters,
with membership options including annual, monthly, and single-ride.

## Business Model
- B2C recreational trips (casual day-pass riders)
- B2C commuter memberships (annual and monthly subscribers)
- B2B employer programs: Citi Bike for Business (subsidized corporate memberships)
- Revenue: per-trip fees, membership subscriptions, corporate contracts

## Key Stakeholders
| Role | Analytics Need |
|------|---------------|
| VP Operations | Station rebalancing, fleet utilization, bike retirement |
| Finance | Trip revenue, cost allocation, program profitability |
| Product | Rider behavior, membership conversion, retention |
| B2B/Partnerships | Commuter corridor identification for employer program expansion |

## Strategic Context
Lyft is expanding the Citi Bike for Business employer subsidy program
and needs analytical foundations to:
1. Identify which stations anchor commuter corridors
2. Understand seasonal vs year-round commuter patterns for contract pricing
3. Quantify weather impact on ridership for operational planning
4. Build the metric foundations layer that scales with the B2B program

## Technical Context - Schema Migration
Q1 2023 data uses the legacy Citi Bike export format (pre-Lyft standardization):
- Column names contain spaces (e.g. 'start station id')
- No ride_id natural key
- usertype field: 'Subscriber' or 'Customer'
- Timestamps as nanosecond Unix integers

Q4 2023 data uses Lyft's standardized format (post-migration):
- Snake_case column names
- ride_id natural key present
- member_casual field: 'member' or 'casual'
- rideable_type field distinguishing classic vs electric bikes
- Timestamps as nanosecond Unix integers

This schema migration happened during 2023 as Lyft unified data exports
across all its bike-share markets (Citi Bike NYC, Divvy Chicago, etc.)

## Data Assets Provided
| Table | Period | Rows | Notes |
|-------|--------|------|-------|
| trips_2023_q1 | Jan-Mar 2023 | 800,000 | Legacy schema format |
| trips_2023_q4 | Oct-Dec 2023 | 800,000 | New Lyft schema format |
| stations | Current | 2,303 | IDs have decimal suffix |
| station_history | Historical SCD | 460 | HIST_ prefix on old IDs |
| weather_hourly | Full year 2023 | 8,760 | NOAA NYC Central Park |
| bike_inventory | Fleet lifecycle | 15,600 | Added/retired events |

## Existing B2B Program Context
Citi Bike for Business already exists and offers:
- Subsidized annual memberships for employees
- Bulk pricing for corporate accounts
- Station-level usage reporting for HR/sustainability teams

The analytical gap: no governed definitions for commuter utilization,
subsidy attribution, or station-level B2B performance metrics.
This engagement builds that foundation.