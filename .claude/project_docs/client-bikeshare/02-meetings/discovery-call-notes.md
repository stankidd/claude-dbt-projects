# Discovery Call Notes - NYC Citi Bike / Lyft

**Date:** Pre-engagement (May 2026)
**Attendees:** Mammoth Growth (Stan Kidd), Client VP Operations, Head of Data

## What They Asked For
1. A clean queryable warehouse — analysts currently hit raw tables directly
2. One analytical finding that demonstrates what is possible with this data
3. Analytical foundation for expanding the Citi Bike for Business employer program
4. Understanding of which stations anchor commuter corridors

## Pain Points Identified
- Q1 and Q4 trip data have incompatible schemas due to Lyft's 2023 format migration
- Raw timestamps are nanosecond Unix integers — unusable without conversion
- Station IDs have decimal suffixes creating unreliable joins
- station_history uses HIST_ prefixed IDs adding further join complexity
- No definition of commuter station vs leisure station exists today
- Weather impact on ridership is assumed but never quantified or governed
- Citi Bike for Business lacks metric foundations — every team calculates
  commuter utilization differently

## Business Questions Prioritized
1. Which stations are commuter anchors vs leisure destinations?
2. Do commuter patterns hold stable across Q1 (winter) and Q4 (fall)?
   Stable = justifies annual contract pricing for employer programs
3. How does weather affect ridership — and does it affect commuter
   stations differently than leisure stations?
4. Which bikes are aging and approaching retirement?

## Key Insight Identified
The Q1/Q4 seasonal comparison is uniquely valuable for B2B pricing:
- Commuter stations with stable year-round ridership justify annual contracts
- Leisure stations with heavy seasonal variation justify quarterly contracts
- This segmentation does not currently exist in any governed form

## Follow-On Engagement Opportunities
1. Full metric foundations layer: commuter utilization, subsidy attribution,
   trip profitability by station type and membership tier
2. Predictive rebalancing model using weather + commuter pattern data
3. Fleet retirement optimization using bike_inventory lifecycle data
4. Real-time operational dashboard for station-level rebalancing decisions
5. B2B contract pricing model based on station type and seasonal stability

## Decisions Made
- Build medallion architecture: bronze -> silver -> gold
- Unify Q1 and Q4 schemas in silver layer (not bronze — keep bronze pure)
- Novel insight: commuter vs leisure station classification with
  seasonal stability scoring for B2B contract pricing
- Include weather join in silver/gold for operational richness
- Scope to available Q1 + Q4 data — note Q2/Q3 gap in README_SOLUTION

## Connection to Metric Foundations
This engagement delivers the first layer of governed metric definitions
that Citi Bike for Business needs to scale:
- station_type (commuter vs leisure) — reusable dimension
- seasonal_stability — reusable for contract pricing
- weekday_weekend_ratio — reusable commuter utilization proxy
- peak_hour_pct — reusable commuter pattern indicator

These become the building blocks of a full metric foundations layer
in a follow-on engagement.