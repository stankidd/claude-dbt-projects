# Pharma Sales Effectiveness -- Technical Specification

**Client:** Mammoth Pharma (fictional)
**BRD Source:** `.claude/project_docs/client-pharma_sales/03-requirements/pharma-sales-brd.md`
**Author:** Stan Kidd
**Date:** 2026-05-25
**Status:** Ready to Build

---

## Business Context

A specialty pharmaceutical company needs a unified analytics layer that connects
rep call activity to prescription outcomes across 20 territories and 42 target
physicians. The pipeline replaces a manual 2-day spreadsheet process with a
weekly self-service scorecard answering: which reps, territories, and physician
segments are driving the most revenue?

---

## Source Data

All sources are dbt seeds (CSV files) located in `seeds/pharma_sales/`.
Bronze models reference seeds using `ref('seed_name')` -- no sources.yml required.
Run `dbt seed` before building bronze models.

| Seed File | Rows | Grain | Key Columns |
|-----------|------|-------|-------------|
| seed_territories | 20 | One row per territory/rep | territory_id, rep_id, rep_name, region, district |
| seed_physicians | 42 | One row per physician | physician_id, territory_id, specialty, tier |
| seed_products | 8 | One row per product | product_id, product_name, therapeutic_area, is_specialty |
| seed_sales_calls | 60 | One row per sales call | call_id, rep_id, physician_id, product_id, call_outcome, discussion_minutes |
| seed_prescriptions | 50 | One row per prescription | rx_id, physician_id, product_id, territory_id, total_revenue_usd, new_patient, prescription_type |

### Data Profile Findings (verified 2026-05-25)

| Field | Profiled Values |
|-------|----------------|
| call_outcome | Positive, Neutral, Negative |
| call_type | Detail, Follow-up |
| prescription_type | New, Refill |
| physician tier | Tier 1, Tier 2, Tier 3 |
| physician specialty | Oncology, Primary Care, Cardiology |
| region | Midwest, Northeast, West, South |
| is_specialty | CSV string 'true'/'false' -- must cast to BOOLEAN |
| new_patient | CSV string 'true'/'false' -- must cast to BOOLEAN |
| follow_up_required | CSV string 'true'/'false' -- must cast to BOOLEAN |
| Date range (calls) | 2024-01-08 to 2024-03-15 |
| Date range (prescriptions) | 2024-01-15 to 2024-03-25 |

> **Note:** Products PROD003, PROD005, PROD006, PROD007 have no calls or
> prescriptions in the data. They exist in the product catalog but are
> not yet promoted. No filtering needed -- all products should be in bronze.

---

## Architecture Overview

```
dbt seeds (CSV files in seeds/pharma_sales/)
  seed_territories, seed_physicians, seed_products,
  seed_sales_calls, seed_prescriptions
        |
        v  (ref() -- no source() needed)
  Bronze (views -- rename + cast only, no business logic)
  bronze_territories
  bronze_physicians
  bronze_products
  bronze_sales_calls
  bronze_prescriptions
        |
        v
  Silver (tables -- joins, enrichment, derived columns)
  silver_sales_activity        (one row per call, enriched)
  silver_prescription_activity (one row per prescription, enriched)
        |
        v
  Gold (tables -- aggregated metrics by business dimension)
  gold_rep_performance         (one row per sales rep)
  gold_physician_scorecard     (one row per physician)
  gold_product_performance     (one row per product)
  gold_territory_summary       (one row per territory)
```

### dbt_project.yml addition required

Add the following under `models: mammoth_test:` before building:

```yaml
pharma_sales:
  bronze:
    +materialized: view
    +tags: ['bronze', 'pharma_sales']
  silver:
    +materialized: table
    +tags: ['silver', 'pharma_sales']
  gold:
    +materialized: table
    +tags: ['gold', 'pharma_sales']
```

---

## Bronze Models

Bronze models reference seeds directly with `ref()`. No joins. No business logic.
All boolean fields must be cast: `CAST(column AS BOOLEAN)`.

---

### bronze_territories

- **File:** `models/pharma_sales/bronze/bronze_territories.sql`
- **Source:** `ref('seed_territories')`
- **Grain:** One row per territory (20 rows)
- **Purpose:** Parse and rename raw territory/rep master data

| Target Column | Source Column | Type | Notes |
|--------------|--------------|------|-------|
| territory_id | territory_id | varchar | PK |
| territory_name | territory_name | varchar | |
| region | region | varchar | Midwest, Northeast, West, South |
| district | district | varchar | |
| rep_id | rep_id | varchar | |
| rep_name | rep_name | varchar | |
| rep_hire_date | rep_hire_date | date | CAST to DATE |

**Tests:**
- territory_id: unique, not_null
- rep_id: not_null
- region: accepted_values ['Midwest', 'Northeast', 'West', 'South']

---

### bronze_physicians

- **File:** `models/pharma_sales/bronze/bronze_physicians.sql`
- **Source:** `ref('seed_physicians')`
- **Grain:** One row per physician (42 rows)
- **Purpose:** Parse and rename raw physician master data

| Target Column | Source Column | Type | Notes |
|--------------|--------------|------|-------|
| physician_id | physician_id | varchar | PK |
| physician_name | physician_name | varchar | |
| specialty | specialty | varchar | Oncology, Primary Care, Cardiology |
| practice_name | practice_name | varchar | |
| city | city | varchar | |
| state | state | varchar | |
| territory_id | territory_id | varchar | FK to territories |
| tier | tier | varchar | Tier 1, Tier 2, Tier 3 |
| years_in_practice | years_in_practice | integer | |

**Tests:**
- physician_id: unique, not_null
- territory_id: not_null
- specialty: accepted_values ['Oncology', 'Primary Care', 'Cardiology']
- tier: accepted_values ['Tier 1', 'Tier 2', 'Tier 3']

---

### bronze_products

- **File:** `models/pharma_sales/bronze/bronze_products.sql`
- **Source:** `ref('seed_products')`
- **Grain:** One row per product (8 rows)
- **Purpose:** Parse and rename raw product catalog data

| Target Column | Source Column | Type | Notes |
|--------------|--------------|------|-------|
| product_id | product_id | varchar | PK |
| product_name | product_name | varchar | |
| generic_name | generic_name | varchar | |
| therapeutic_area | therapeutic_area | varchar | |
| drug_class | drug_class | varchar | |
| formulation | formulation | varchar | |
| dosage_strength | dosage_strength | varchar | |
| list_price_usd | list_price_usd | numeric | |
| launch_date | launch_date | date | CAST to DATE |
| is_specialty | is_specialty | boolean | CAST('true'/'false' string to BOOLEAN) |

**Tests:**
- product_id: unique, not_null
- is_specialty: not_null

---

### bronze_sales_calls

- **File:** `models/pharma_sales/bronze/bronze_sales_calls.sql`
- **Source:** `ref('seed_sales_calls')`
- **Grain:** One row per sales call (60 rows)
- **Purpose:** Parse and rename raw call activity data

| Target Column | Source Column | Type | Notes |
|--------------|--------------|------|-------|
| call_id | call_id | varchar | PK |
| call_date | call_date | date | CAST to DATE |
| rep_id | rep_id | varchar | FK to territories |
| territory_id | territory_id | varchar | FK to territories |
| physician_id | physician_id | varchar | FK to physicians |
| product_id | product_id | varchar | FK to products |
| call_type | call_type | varchar | Detail, Follow-up |
| call_outcome | call_outcome | varchar | Positive, Neutral, Negative |
| samples_left | samples_left | integer | |
| discussion_minutes | discussion_minutes | integer | |
| follow_up_required | follow_up_required | boolean | CAST string to BOOLEAN |

**Tests:**
- call_id: unique, not_null
- rep_id: not_null
- physician_id: not_null
- product_id: not_null
- call_outcome: accepted_values ['Positive', 'Neutral', 'Negative']
- call_type: accepted_values ['Detail', 'Follow-up']

---

### bronze_prescriptions

- **File:** `models/pharma_sales/bronze/bronze_prescriptions.sql`
- **Source:** `ref('seed_prescriptions')`
- **Grain:** One row per prescription (50 rows)
- **Purpose:** Parse and rename raw prescription outcome data

| Target Column | Source Column | Type | Notes |
|--------------|--------------|------|-------|
| rx_id | rx_id | varchar | PK |
| rx_date | rx_date | date | CAST to DATE |
| physician_id | physician_id | varchar | FK to physicians |
| product_id | product_id | varchar | FK to products |
| territory_id | territory_id | varchar | FK to territories |
| quantity_units | quantity_units | integer | |
| total_revenue_usd | total_revenue_usd | numeric | |
| new_patient | new_patient | boolean | CAST string to BOOLEAN |
| prescription_type | prescription_type | varchar | New, Refill |

**Tests:**
- rx_id: unique, not_null
- physician_id: not_null
- product_id: not_null
- territory_id: not_null
- total_revenue_usd: not_null
- prescription_type: accepted_values ['New', 'Refill']

---

## Silver Models

Silver models join bronze models and derive all business metrics needed by gold.
All silver models reference bronze only via ref() -- never seed_ tables directly.

---

### silver_sales_activity

- **File:** `models/pharma_sales/silver/silver_sales_activity.sql`
- **Depends on:** bronze_sales_calls, bronze_physicians, bronze_territories, bronze_products
- **Grain:** One row per sales call (60 rows)
- **Purpose:** Enrich calls with physician tier/specialty, territory/rep detail, and product info;
  derive is_positive_call flag for gold aggregations

#### Join Logic

| Left | Right | Key | Type | Cardinality |
|------|-------|-----|------|-------------|
| bronze_sales_calls (c) | bronze_physicians (ph) | c.physician_id = ph.physician_id | INNER JOIN | many-to-one |
| bronze_sales_calls (c) | bronze_territories (t) | c.territory_id = t.territory_id | INNER JOIN | many-to-one |
| bronze_sales_calls (c) | bronze_products (p) | c.product_id = p.product_id | INNER JOIN | many-to-one |

No filters -- all calls included.

#### Column Definitions

| Column | Type | Source / Logic |
|--------|------|----------------|
| call_id | varchar | `c.call_id` |
| call_date | date | `c.call_date` |
| rep_id | varchar | `c.rep_id` |
| rep_name | varchar | `t.rep_name` |
| territory_id | varchar | `c.territory_id` |
| territory_name | varchar | `t.territory_name` |
| region | varchar | `t.region` |
| district | varchar | `t.district` |
| physician_id | varchar | `c.physician_id` |
| physician_name | varchar | `ph.physician_name` |
| specialty | varchar | `ph.specialty` |
| tier | varchar | `ph.tier` |
| product_id | varchar | `c.product_id` |
| product_name | varchar | `p.product_name` |
| therapeutic_area | varchar | `p.therapeutic_area` |
| is_specialty_product | boolean | `p.is_specialty` |
| call_type | varchar | `c.call_type` |
| call_outcome | varchar | `c.call_outcome` |
| is_positive_call | boolean | `c.call_outcome = 'Positive'` |
| samples_left | integer | `c.samples_left` |
| discussion_minutes | integer | `c.discussion_minutes` |
| follow_up_required | boolean | `c.follow_up_required` |

#### Tests

| Column(s) | Test |
|-----------|------|
| call_id | unique, not_null |
| rep_id | not_null |
| physician_id | not_null |
| territory_id | not_null |
| product_id | not_null |
| is_positive_call | not_null |

---

### silver_prescription_activity

- **File:** `models/pharma_sales/silver/silver_prescription_activity.sql`
- **Depends on:** bronze_prescriptions, bronze_physicians, bronze_territories, bronze_products
- **Grain:** One row per prescription (50 rows)
- **Purpose:** Enrich prescriptions with physician tier/specialty, territory/rep detail, and product
  info; derive is_new_patient and is_refill flags for gold aggregations

#### Join Logic

| Left | Right | Key | Type | Cardinality |
|------|-------|-----|------|-------------|
| bronze_prescriptions (rx) | bronze_physicians (ph) | rx.physician_id = ph.physician_id | INNER JOIN | many-to-one |
| bronze_prescriptions (rx) | bronze_territories (t) | rx.territory_id = t.territory_id | INNER JOIN | many-to-one |
| bronze_prescriptions (rx) | bronze_products (p) | rx.product_id = p.product_id | INNER JOIN | many-to-one |

No filters -- all prescriptions included.

#### Column Definitions

| Column | Type | Source / Logic |
|--------|------|----------------|
| rx_id | varchar | `rx.rx_id` |
| rx_date | date | `rx.rx_date` |
| rep_id | varchar | `t.rep_id` |
| rep_name | varchar | `t.rep_name` |
| territory_id | varchar | `rx.territory_id` |
| territory_name | varchar | `t.territory_name` |
| region | varchar | `t.region` |
| district | varchar | `t.district` |
| physician_id | varchar | `rx.physician_id` |
| physician_name | varchar | `ph.physician_name` |
| specialty | varchar | `ph.specialty` |
| tier | varchar | `ph.tier` |
| product_id | varchar | `rx.product_id` |
| product_name | varchar | `p.product_name` |
| therapeutic_area | varchar | `p.therapeutic_area` |
| is_specialty_product | boolean | `p.is_specialty` |
| quantity_units | integer | `rx.quantity_units` |
| total_revenue_usd | numeric | `rx.total_revenue_usd` |
| prescription_type | varchar | `rx.prescription_type` |
| is_new_patient | boolean | `rx.new_patient` |
| is_refill | boolean | `rx.prescription_type = 'Refill'` |

#### Tests

| Column(s) | Test |
|-----------|------|
| rx_id | unique, not_null |
| physician_id | not_null |
| territory_id | not_null |
| product_id | not_null |
| total_revenue_usd | not_null |
| is_new_patient | not_null |
| is_refill | not_null |

---

## Gold Models

Gold models aggregate from silver only. All BRD metrics are implemented here.
Each model uses two CTEs (call_metrics + rx_metrics) joined on the grain key,
then derives ratio metrics in a final SELECT.

---

### gold_rep_performance

- **File:** `models/pharma_sales/gold/gold_rep_performance.sql`
- **Depends on:** silver_sales_activity, silver_prescription_activity
- **Grain:** One row per sales rep (20 rows expected)
- **Purpose:** Full rep scorecard for performance reviews, coaching prioritization,
  and territory realignment decisions.

#### Implementation Pattern

```
call_metrics CTE  -- aggregate silver_sales_activity by rep_id
rx_metrics CTE    -- aggregate silver_prescription_activity by rep_id
joined CTE        -- LEFT JOIN call_metrics to rx_metrics on rep_id
final SELECT      -- compute ratio metrics
```

#### Aggregations

| Column | Type | SQL Logic | BRD Metric |
|--------|------|-----------|------------|
| rep_id | varchar | `rep_id` (GROUP BY in call_metrics) | -- |
| rep_name | varchar | `MAX(rep_name)` | -- |
| territory_id | varchar | `MAX(territory_id)` | -- |
| territory_name | varchar | `MAX(territory_name)` | -- |
| region | varchar | `MAX(region)` | -- |
| district | varchar | `MAX(district)` | -- |
| total_calls | integer | `COUNT(*)` from call_metrics | Total Calls |
| total_prescriptions | integer | `COUNT(*)` from rx_metrics | Total Prescriptions |
| total_revenue | numeric | `SUM(total_revenue_usd)` from rx_metrics | Total Revenue |
| new_patient_revenue | numeric | `SUM(CASE WHEN is_new_patient THEN total_revenue_usd ELSE 0 END)` | New Patient Revenue |
| refill_revenue | numeric | `SUM(CASE WHEN is_refill THEN total_revenue_usd ELSE 0 END)` | Refill Revenue |
| positive_calls | integer | `SUM(IFF(is_positive_call, 1, 0))` from call_metrics | -- |
| distinct_physicians_called | integer | `COUNT(DISTINCT physician_id)` from call_metrics | -- |
| avg_discussion_minutes | numeric | `AVG(discussion_minutes)` from call_metrics | Avg Discussion Minutes |
| conversion_rate | numeric | `total_prescriptions / total_calls` | Conversion Rate |
| revenue_per_call | numeric | `total_revenue / total_calls` | Revenue Per Call |
| positive_call_rate | numeric | `positive_calls / total_calls` | Positive Call Rate |
| calls_per_physician | numeric | `total_calls / distinct_physicians_called` | Calls Per Physician |

#### Tests

| Column(s) | Test |
|-----------|------|
| rep_id | unique, not_null |
| total_calls | not_null |
| total_revenue | not_null |
| avg_discussion_minutes | not_null |

---

### gold_physician_scorecard

- **File:** `models/pharma_sales/gold/gold_physician_scorecard.sql`
- **Depends on:** silver_sales_activity, silver_prescription_activity
- **Grain:** One row per physician (42 rows expected)
- **Purpose:** Physician value ranking for targeting tier adjustments and
  identification of high-potential physicians not yet prescribing.

#### Implementation Pattern

```
call_metrics CTE  -- aggregate silver_sales_activity by physician_id
rx_metrics CTE    -- aggregate silver_prescription_activity by physician_id
joined CTE        -- LEFT JOIN call_metrics to rx_metrics on physician_id
```

#### Aggregations

| Column | Type | SQL Logic | BRD Metric |
|--------|------|-----------|------------|
| physician_id | varchar | GROUP BY | -- |
| physician_name | varchar | `MAX(physician_name)` | -- |
| specialty | varchar | `MAX(specialty)` | -- |
| tier | varchar | `MAX(tier)` | -- |
| territory_id | varchar | `MAX(territory_id)` | -- |
| territory_name | varchar | `MAX(territory_name)` | -- |
| total_calls | integer | `COUNT(*)` from call_metrics | Total Calls |
| total_prescriptions | integer | `COUNT(*)` from rx_metrics | Total Prescriptions |
| total_revenue | numeric | `SUM(total_revenue_usd)` | Total Revenue |
| new_patient_revenue | numeric | `SUM(CASE WHEN is_new_patient THEN total_revenue_usd ELSE 0 END)` | New Patient Revenue |
| refill_revenue | numeric | `SUM(CASE WHEN is_refill THEN total_revenue_usd ELSE 0 END)` | Refill Revenue |
| avg_discussion_minutes | numeric | `AVG(discussion_minutes)` from call_metrics | Avg Discussion Minutes |
| positive_call_rate | numeric | `SUM(IFF(is_positive_call,1,0)) / COUNT(*)` from call_metrics | Positive Call Rate |
| conversion_rate | numeric | `total_prescriptions / NULLIF(total_calls, 0)` | Conversion Rate |

#### Tests

| Column(s) | Test |
|-----------|------|
| physician_id | unique, not_null |
| total_revenue | not_null |

---

### gold_product_performance

- **File:** `models/pharma_sales/gold/gold_product_performance.sql`
- **Depends on:** silver_sales_activity, silver_prescription_activity
- **Grain:** One row per product (up to 8 rows -- products with no activity will show nulls)
- **Purpose:** Product traction analysis for promotion budget allocation decisions.

#### Implementation Pattern

```
all_products CTE  -- SELECT * FROM ref('bronze_products') as the base
call_metrics CTE  -- aggregate silver_sales_activity by product_id
rx_metrics CTE    -- aggregate silver_prescription_activity by product_id
joined CTE        -- LEFT JOIN all_products to call_metrics and rx_metrics
```

> Products with no calls or prescriptions (PROD003, PROD005, PROD006, PROD007)
> should appear in the output with 0/NULL metrics -- use the product catalog
> as the base to ensure completeness.

#### Aggregations

| Column | Type | SQL Logic | BRD Metric |
|--------|------|-----------|------------|
| product_id | varchar | from bronze_products | -- |
| product_name | varchar | from bronze_products | -- |
| therapeutic_area | varchar | from bronze_products | -- |
| drug_class | varchar | from bronze_products | -- |
| is_specialty_product | boolean | from bronze_products | -- |
| launch_date | date | from bronze_products | -- |
| total_calls | integer | `COALESCE(COUNT(*), 0)` from call_metrics | Total Calls |
| total_prescriptions | integer | `COALESCE(COUNT(*), 0)` from rx_metrics | Total Prescriptions |
| total_revenue | numeric | `COALESCE(SUM(total_revenue_usd), 0)` | Total Revenue |
| new_patient_revenue | numeric | `COALESCE(SUM(CASE WHEN is_new_patient THEN total_revenue_usd ELSE 0 END), 0)` | New Patient Revenue |
| refill_revenue | numeric | `COALESCE(SUM(CASE WHEN is_refill THEN total_revenue_usd ELSE 0 END), 0)` | Refill Revenue |
| conversion_rate | numeric | `total_prescriptions / NULLIF(total_calls, 0)` | Conversion Rate |

#### Tests

| Column(s) | Test |
|-----------|------|
| product_id | unique, not_null |
| product_name | not_null |

---

### gold_territory_summary

- **File:** `models/pharma_sales/gold/gold_territory_summary.sql`
- **Depends on:** silver_sales_activity, silver_prescription_activity
- **Grain:** One row per territory (20 rows expected)
- **Purpose:** Territory performance vs. call investment for territory realignment
  and rep coaching decisions.

#### Implementation Pattern

```
call_metrics CTE  -- aggregate silver_sales_activity by territory_id
rx_metrics CTE    -- aggregate silver_prescription_activity by territory_id
joined CTE        -- LEFT JOIN call_metrics to rx_metrics on territory_id
```

#### Aggregations

| Column | Type | SQL Logic | BRD Metric |
|--------|------|-----------|------------|
| territory_id | varchar | GROUP BY | -- |
| territory_name | varchar | `MAX(territory_name)` | -- |
| region | varchar | `MAX(region)` | -- |
| district | varchar | `MAX(district)` | -- |
| rep_id | varchar | `MAX(rep_id)` | -- |
| rep_name | varchar | `MAX(rep_name)` | -- |
| total_calls | integer | `COUNT(*)` from call_metrics | Total Calls |
| total_prescriptions | integer | `COUNT(*)` from rx_metrics | Total Prescriptions |
| total_revenue | numeric | `SUM(total_revenue_usd)` | Total Revenue |
| new_patient_revenue | numeric | `SUM(CASE WHEN is_new_patient THEN total_revenue_usd ELSE 0 END)` | New Patient Revenue |
| refill_revenue | numeric | `SUM(CASE WHEN is_refill THEN total_revenue_usd ELSE 0 END)` | Refill Revenue |
| distinct_physicians_called | integer | `COUNT(DISTINCT physician_id)` from call_metrics | -- |
| avg_discussion_minutes | numeric | `AVG(discussion_minutes)` from call_metrics | Avg Discussion Minutes |
| positive_call_rate | numeric | `SUM(IFF(is_positive_call,1,0)) / COUNT(*)` | Positive Call Rate |
| conversion_rate | numeric | `total_prescriptions / NULLIF(total_calls, 0)` | Conversion Rate |
| revenue_per_call | numeric | `total_revenue / NULLIF(total_calls, 0)` | Revenue Per Call |
| calls_per_physician | numeric | `total_calls / NULLIF(distinct_physicians_called, 0)` | Calls Per Physician |

#### Tests

| Column(s) | Test |
|-----------|------|
| territory_id | unique, not_null |
| total_calls | not_null |

---

## Tests Summary

| Model | Test | Column(s) |
|-------|------|-----------|
| bronze_territories | unique, not_null | territory_id |
| bronze_territories | not_null | rep_id |
| bronze_territories | accepted_values | region |
| bronze_physicians | unique, not_null | physician_id |
| bronze_physicians | not_null | territory_id |
| bronze_physicians | accepted_values | specialty, tier |
| bronze_products | unique, not_null | product_id |
| bronze_products | not_null | is_specialty |
| bronze_sales_calls | unique, not_null | call_id |
| bronze_sales_calls | not_null | rep_id, physician_id, product_id |
| bronze_sales_calls | accepted_values | call_outcome, call_type |
| bronze_prescriptions | unique, not_null | rx_id |
| bronze_prescriptions | not_null | physician_id, product_id, territory_id, total_revenue_usd |
| bronze_prescriptions | accepted_values | prescription_type |
| silver_sales_activity | unique, not_null | call_id |
| silver_sales_activity | not_null | rep_id, physician_id, territory_id, product_id, is_positive_call |
| silver_prescription_activity | unique, not_null | rx_id |
| silver_prescription_activity | not_null | physician_id, territory_id, product_id, total_revenue_usd, is_new_patient, is_refill |
| gold_rep_performance | unique, not_null | rep_id |
| gold_rep_performance | not_null | total_calls, total_revenue, avg_discussion_minutes |
| gold_physician_scorecard | unique, not_null | physician_id |
| gold_physician_scorecard | not_null | total_revenue |
| gold_product_performance | unique, not_null | product_id |
| gold_product_performance | not_null | product_name |
| gold_territory_summary | unique, not_null | territory_id |
| gold_territory_summary | not_null | total_calls |

**Total expected tests: ~40**

---

## Definition of Done

- [ ] `dbt seed` run successfully (all 5 seeds loaded)
- [ ] `dbt_project.yml` updated with pharma_sales model config
- [ ] All 5 bronze models build without errors
- [ ] silver_sales_activity builds without errors
- [ ] silver_prescription_activity builds without errors
- [ ] gold_rep_performance builds without errors
- [ ] gold_physician_scorecard builds without errors
- [ ] gold_product_performance builds without errors
- [ ] gold_territory_summary builds without errors
- [ ] All tests pass (zero failures)
- [ ] All columns documented in schema.yml with descriptions
- [ ] No hardcoded database or schema references
- [ ] All SQL keywords uppercase
- [ ] All field names lowercase_with_underscores
- [ ] PR created with full summary and checklist complete
