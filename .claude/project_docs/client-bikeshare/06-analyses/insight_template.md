# Novel Insight: Commuter Station Classification
## Citi Bike for Business — Expansion Foundation

### The Business Question
Which stations anchor commuter corridors and are suitable for
Citi Bike for Business employer subsidy program expansion?
Which of those are seasonally stable enough to justify annual pricing?

### Method
Classified each station using trip pattern signals from unified
Q1 + Q4 data (1.6M trips, Jan-Mar and Oct-Dec 2023):

- **Commuter station:** weekday/weekend ratio > 1.5x
  AND peak hour trips (7-9am + 5-7pm) > 25% of daily trips
- **Seasonally stable:** Q1 vs Q4 trip variance < 20%

### SQL
See insight/commuter_station_analysis.sql

### Findings
[FILL IN AFTER RUNNING gold_station_performance]

| Station Type | Seasonal Pattern | Count | Avg Trips | Avg Member Rate | Avg Peak % |
|-------------|-----------------|-------|-----------|-----------------|------------|
| Commuter | Stable | [X] | [X] | [X]% | [X]% |
| Commuter | Seasonal | [X] | [X] | [X]% | [X]% |
| Leisure | Stable | [X] | [X] | [X]% | [X]% |
| Leisure | Seasonal | [X] | [X] | [X]% | [X]% |

### Interpretation
[FILL IN — key observations about member rates, trip volumes, seasonal patterns]

### Business Recommendation
Stable commuter stations (top [N]) are the highest-priority targets
for Citi Bike for Business expansion because:
1. Year-round ridership justifies annual contract pricing
2. High member rates indicate existing subscriber base to build on
3. Predictable AM/PM peaks align with employer subsidy use cases

### What This Enables Next
This classification is the first governed definition of commuter_utilization
in Citi Bike's analytics stack. It becomes the dimensional anchor for a
full metric foundations layer covering subsidy attribution, trip
profitability by station type, and B2B revenue recognition.