# Supplier Performance Analysis — Technical Specification

**Client:** TPCH Analytics
**BRD Source:** `.claude/project_docs/client-tpch_sf10/03-requirements/supplier-performance-brd.md`
**Author:** Stan Kidd
**Date:** 2026-05-24
**Status:** Ready to Build

---

## Business Context

The supply chain team needs a self-service analytics layer to evaluate supplier
performance across delivery timeliness, discount behavior, and order volume.
Currently this analysis is produced manually in spreadsheets over two days.
This pipeline produces a daily-refreshing supplier scorecard, nation-level
summary, and supplier x part-type breakdown.

---

## Source Data

| Table | Snowflake Path | Grain | Rows (SF10) |
|-------|---------------|-------|-------------|
| LINEITEM | SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.LINEITEM | One row per order line item | 59,986,052 |
| SUPPLIER | SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.SUPPLIER | One row per supplier | 100,000 |
| NATION | SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.NATION | One row per nation | 25 |
| PART | SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.PART | One row per part | 2,000,000 |
| ORDERS | ~~SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.ORDERS~~ | Not required | -- |

> **Note:** ORDERS is listed in the BRD data sources but no defined metric
> requires it. All metrics are computed at line_item grain.
> The `tpch_sf10` source is already defined in
> `models/tpch_sf10/bronze/tpch_sf10_sources.yml`.

---

## Architecture Overview

```
SNOWFLAKE_SAMPLE_DATA.TPCH_SF10
  LINEITEM, SUPPLIER, NATION, PART
       |
       v
  Bronze (views -- rename only, already built)
  sf10_bronze_lineitem
  sf10_bronze_supplier
  sf10_bronze_nation
  sf10_bronze_part
       |
       v
  Silver (table -- line_item grain, enriched + derived columns)
  sf10_silver_supplier_performance
       |
       v
  Gold (tables -- aggregated metrics)
  sf10_gold_supplier_scorecard        (one row per supplier)
  sf10_gold_nation_performance        (one row per nation)
  sf10_gold_supplier_part_performance (one row per supplier x part_type)
```

---

## Data Profile Findings

Profiled against TPCH_SF10 on 2026-05-24:

| Metric | Value |
|--------|-------|
| Total line items | 59,986,052 |
| Unique suppliers in lineitem | 100,000 (all suppliers active) |
| Late shipments (ship_date > commit_date) | 30,242,410 (50.4%) |
| Avg days late (late shipments only) | 33.5 days |
| Return flags: N / R / A | 30.4M / 14.8M / 14.8M |
| Return rate (flag = R) | 24.7% |
| Distinct part types | 150 |

**No discrepancies found** between BRD assumptions and actual source data.
All column names confirmed against bronze views.

---

## Bronze Models

All bronze models are already built and tested. No new bronze models required.

| Model | Status |
|-------|--------|
| sf10_bronze_lineitem | Built and tested |
| sf10_bronze_supplier | Built and tested |
| sf10_bronze_nation | Built and tested |
| sf10_bronze_part | Built and tested |

---

## Silver Models

### sf10_silver_supplier_performance

- **Model name:** `sf10_silver_supplier_performance`
- **Depends on:** `sf10_bronze_lineitem`, `sf10_bronze_supplier`, `sf10_bronze_nation`, `sf10_bronze_part`
- **Materialization:** table
- **Grain:** One row per order line item (59,986,052 rows expected)
- **Purpose:** Enrich line items with supplier, nation, and part information;
  derive all performance metrics needed by the three gold models.

> **Grain clarification:** The BRD defines silver grain as "one row per
> supplier" but that would prevent `gold_supplier_part_performance` (supplier
> x part_type grain) from being derivable from silver. Silver is correctly
> kept at line_item grain to enable all three gold aggregations.

#### Join Logic

| Left Table | Right Table | Join Key | Join Type | Cardinality |
|------------|-------------|----------|-----------|-------------|
| sf10_bronze_lineitem (li) | sf10_bronze_supplier (s) | li.supplier_id = s.supplier_id | INNER JOIN | many-to-one |
| sf10_bronze_supplier (s) | sf10_bronze_nation (n) | s.nation_id = n.nation_id | INNER JOIN | many-to-one |
| sf10_bronze_lineitem (li) | sf10_bronze_part (p) | li.part_id = p.part_id | INNER JOIN | many-to-one |

No filters applied -- all line items included.

#### Column Definitions

| Column | Type | Source / Logic |
|--------|------|----------------|
| order_id | integer | `li.order_id` |
| line_number | integer | `li.line_number` |
| supplier_id | integer | `li.supplier_id` |
| supplier_name | varchar | `s.supplier_name` |
| nation_name | varchar | `n.nation_name` |
| part_id | integer | `li.part_id` |
| part_type | varchar | `p.part_type` |
| quantity | numeric | `li.quantity` |
| extended_price | numeric | `li.extended_price` |
| discount | numeric | `li.discount` |
| tax | numeric | `li.tax` |
| net_price | numeric | `li.extended_price * (1 - li.discount) * (1 + li.tax)` |
| is_returned | boolean | `li.return_flag = 'R'` |
| is_late_shipment | boolean | `li.ship_date > li.commit_date` |
| days_late | integer | `CASE WHEN li.ship_date > li.commit_date THEN DATEDIFF('day', li.commit_date, li.ship_date) ELSE NULL END` -- NULL for on-time shipments |
| ship_date | date | `li.ship_date` |
| commit_date | date | `li.commit_date` |

#### Tests

| Column(s) | Test |
|-----------|------|
| order_id + line_number | `dbt_utils.unique_combination_of_columns` |
| order_id | `not_null` |
| supplier_id | `not_null` |
| nation_name | `not_null` |
| part_type | `not_null` |
| net_price | `not_null` |
| is_returned | `not_null` |
| is_late_shipment | `not_null` |

---

## Gold Models

### sf10_gold_supplier_scorecard

- **Model name:** `sf10_gold_supplier_scorecard`
- **Depends on:** `sf10_silver_supplier_performance`
- **Materialization:** table
- **Grain:** One row per supplier (100,000 rows expected)
- **Purpose:** Full performance scorecard per supplier for contract negotiation
  and remediation prioritization.

#### Aggregations

| Column | Type | SQL Logic | BRD Metric |
|--------|------|-----------|------------|
| supplier_id | integer | `supplier_id` (GROUP BY) | -- |
| supplier_name | varchar | `MAX(supplier_name)` | -- |
| nation_name | varchar | `MAX(nation_name)` | -- |
| total_revenue | numeric | `SUM(net_price)` | Total Revenue |
| total_line_items | integer | `COUNT(*)` | Total Line Items |
| total_quantity | numeric | `SUM(quantity)` | Total Quantity |
| avg_discount_rate | numeric | `AVG(discount)` | Avg Discount Rate |
| late_shipment_count | integer | `SUM(IFF(is_late_shipment, 1, 0))` | Late Shipment Count |
| late_shipment_rate | numeric | `SUM(IFF(is_late_shipment, 1, 0)) / COUNT(*)` | Late Shipment Rate |
| avg_days_late | numeric | `AVG(days_late)` -- NULLs excluded automatically | Avg Days Late |
| return_count | integer | `SUM(IFF(is_returned, 1, 0))` | Return Count |
| return_rate | numeric | `SUM(IFF(is_returned, 1, 0)) / COUNT(*)` | Return Rate |

#### Tests

| Column(s) | Test |
|-----------|------|
| supplier_id | `unique`, `not_null` |
| total_revenue | `not_null` |
| total_line_items | `not_null` |
| late_shipment_rate | `not_null` |
| return_rate | `not_null` |

---

### sf10_gold_nation_performance

- **Model name:** `sf10_gold_nation_performance`
- **Depends on:** `sf10_silver_supplier_performance`
- **Materialization:** table
- **Grain:** One row per nation (25 rows expected)
- **Purpose:** Regional supply chain performance for sourcing strategy decisions.

#### Aggregations

| Column | Type | SQL Logic | BRD Metric |
|--------|------|-----------|------------|
| nation_name | varchar | `nation_name` (GROUP BY) | -- |
| supplier_count | integer | `COUNT(DISTINCT supplier_id)` | -- |
| total_revenue | numeric | `SUM(net_price)` | Total Revenue |
| total_line_items | integer | `COUNT(*)` | Total Line Items |
| total_quantity | numeric | `SUM(quantity)` | Total Quantity |
| avg_discount_rate | numeric | `AVG(discount)` | Avg Discount Rate |
| late_shipment_count | integer | `SUM(IFF(is_late_shipment, 1, 0))` | Late Shipment Count |
| late_shipment_rate | numeric | `SUM(IFF(is_late_shipment, 1, 0)) / COUNT(*)` | Late Shipment Rate |
| avg_days_late | numeric | `AVG(days_late)` | Avg Days Late |
| return_rate | numeric | `SUM(IFF(is_returned, 1, 0)) / COUNT(*)` | Return Rate |

#### Tests

| Column(s) | Test |
|-----------|------|
| nation_name | `unique`, `not_null` |
| supplier_count | `not_null` |
| total_revenue | `not_null` |
| late_shipment_rate | `not_null` |
| return_rate | `not_null` |

---

### sf10_gold_supplier_part_performance

- **Model name:** `sf10_gold_supplier_part_performance`
- **Depends on:** `sf10_silver_supplier_performance`
- **Materialization:** table
- **Grain:** One row per supplier x part_type (actual rows depend on which suppliers fulfill which part types)
- **Purpose:** Category-level supplier performance for category manager analysis.

#### Aggregations

| Column | Type | SQL Logic | BRD Metric |
|--------|------|-----------|------------|
| supplier_id | integer | `supplier_id` (GROUP BY) | -- |
| supplier_name | varchar | `MAX(supplier_name)` | -- |
| nation_name | varchar | `MAX(nation_name)` | -- |
| part_type | varchar | `part_type` (GROUP BY) | -- |
| total_revenue | numeric | `SUM(net_price)` | Total Revenue |
| total_line_items | integer | `COUNT(*)` | Total Line Items |
| total_quantity | numeric | `SUM(quantity)` | Total Quantity |
| avg_discount_rate | numeric | `AVG(discount)` | Avg Discount Rate |
| late_shipment_rate | numeric | `SUM(IFF(is_late_shipment, 1, 0)) / COUNT(*)` | Late Shipment Rate |
| return_rate | numeric | `SUM(IFF(is_returned, 1, 0)) / COUNT(*)` | Return Rate |

#### Tests

| Column(s) | Test |
|-----------|------|
| supplier_id + part_type | `dbt_utils.unique_combination_of_columns` |
| supplier_id | `not_null` |
| part_type | `not_null` |
| total_revenue | `not_null` |
| late_shipment_rate | `not_null` |
| return_rate | `not_null` |

---

## Tests Summary

| Model | Test | Column(s) |
|-------|------|-----------|
| sf10_silver_supplier_performance | unique_combination_of_columns | order_id, line_number |
| sf10_silver_supplier_performance | not_null | order_id, supplier_id, nation_name, part_type, net_price, is_returned, is_late_shipment |
| sf10_gold_supplier_scorecard | unique | supplier_id |
| sf10_gold_supplier_scorecard | not_null | supplier_id, total_revenue, total_line_items, late_shipment_rate, return_rate |
| sf10_gold_nation_performance | unique | nation_name |
| sf10_gold_nation_performance | not_null | nation_name, supplier_count, total_revenue, late_shipment_rate, return_rate |
| sf10_gold_supplier_part_performance | unique_combination_of_columns | supplier_id, part_type |
| sf10_gold_supplier_part_performance | not_null | supplier_id, part_type, total_revenue, late_shipment_rate, return_rate |

**Total expected tests: ~30**

---

## Definition of Done

- [ ] All bronze models build without errors (already complete)
- [ ] sf10_silver_supplier_performance builds without errors
- [ ] sf10_gold_supplier_scorecard builds without errors
- [ ] sf10_gold_nation_performance builds without errors
- [ ] sf10_gold_supplier_part_performance builds without errors
- [ ] All tests pass (zero failures)
- [ ] All columns documented in schema.yml with descriptions
- [ ] No hardcoded database or schema references
- [ ] All SQL keywords uppercase
- [ ] All field names lowercase_with_underscores
- [ ] PR created with full summary and checklist complete
