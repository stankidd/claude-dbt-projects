# Supplier Performance Analysis — Business Requirements Document

**Client:** TPCH Analytics
**Version:** 1.0
**Status:** Approved for Tech Spec
**Requestor:** VP of Supply Chain
**Date:** May 2026

---

## Business Context

The supply chain team needs to understand which suppliers are delivering
the best performance across delivery timeliness, discount rates, and
order volume. Currently this analysis is done manually in spreadsheets
each month and takes two days to produce. Leadership wants a self-service
analytics layer that answers these questions in real time.

---

## Business Problem

We have thousands of suppliers across 25 nations fulfilling millions of
line items every year. We do not have a single view of supplier performance
that combines delivery timeliness, pricing behavior (discounts), and volume.
Without this view we cannot:
- Identify underperforming suppliers before they impact customer satisfaction
- Negotiate contracts based on actual delivery performance data
- Prioritize supplier relationships that drive the most revenue

---

## Goals

1. Produce a supplier performance scorecard at the supplier level
2. Show delivery performance by nation to identify regional patterns
3. Understand the relationship between discount rates and order volume
4. Identify suppliers with high late shipment rates for remediation
5. Enable the supply chain team to self-serve this analysis daily

---

## Decisions This Will Inform

- Supplier contract renegotiation priorities
- Regional sourcing strategy (which nations to expand or reduce)
- Discount policy review (are high discounts correlated with late delivery?)
- Supplier remediation list (bottom 10% by delivery performance)

---

## Metrics Defined

| Metric | Definition | Owner |
|--------|-----------|-------|
| Total Revenue | SUM of net_price (extended_price * (1 - discount) * (1 + tax)) across all line items | Finance |
| Total Line Items | COUNT of line items fulfilled by supplier | Supply Chain |
| Total Quantity | SUM of quantity across all line items | Supply Chain |
| Avg Discount Rate | AVG of discount across all line items | Finance |
| Late Shipment Count | COUNT of line items where ship_date > commit_date | Supply Chain |
| Late Shipment Rate | Late Shipment Count / Total Line Items as a percentage | Supply Chain |
| Avg Days Late | AVG of (ship_date - commit_date) for late shipments only | Supply Chain |
| Return Count | COUNT of line items where return_flag = R | Supply Chain |
| Return Rate | Return Count / Total Line Items as a percentage | Supply Chain |

---

## Data Sources

| Source Table | System | Description | Refresh |
|-------------|--------|-------------|---------|
| SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.LINEITEM | Snowflake TPCH | One row per order line item | Static sample |
| SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.SUPPLIER | Snowflake TPCH | One row per supplier | Static sample |
| SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.NATION | Snowflake TPCH | One row per nation | Static sample |
| SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.ORDERS | Snowflake TPCH | One row per order | Static sample |
| SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.PART | Snowflake TPCH | One row per part | Static sample |

Note: TPCH_SF10 source is already defined in:
models/tpch_sf10/bronze/tpch_sf10_sources.yml

---

## Grain Definitions

| Model | Grain |
|-------|-------|
| Bronze models | One row per source record (same as source) |
| silver_supplier_performance | One row per supplier |
| gold_supplier_scorecard | One row per supplier |
| gold_nation_performance | One row per nation |
| gold_supplier_part_performance | One row per supplier per part type |

---

## Business Rules

| Rule | Definition |
|------|-----------|
| Late shipment | ship_date > commit_date |
| Returned item | return_flag = R |
| Net price | extended_price * (1 - discount) * (1 + tax) |
| Avg days late | Only calculated for late shipments, not all shipments |
| Supplier nation | Join supplier to nation via nation_id |
| Part type | Join lineitem to part via part_id to get part type |

---

## Reporting Requirements

| Report | Consumer | Frequency |
|--------|---------|-----------|
| Supplier Scorecard | Supply Chain VP | Daily |
| Nation Performance | Regional Managers | Daily |
| Supplier Part Performance | Category Managers | Daily |

---

## Out of Scope

- Supplier contact information or communication tools
- Purchase order management or procurement workflow
- Real-time streaming (daily batch sufficient)
- Cost data beyond what is in TPCH source

---

## Success Criteria

- Supply chain team can identify bottom 10% of suppliers by late shipment rate
- Nation-level performance summary available without manual aggregation
- All metrics match manual spreadsheet calculations within 1%
- Dashboard refresh completes within 5 minutes of dbt run
