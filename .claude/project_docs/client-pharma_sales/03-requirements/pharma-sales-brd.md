# Pharma Sales Effectiveness — Business Requirements Document

**Client:** Mammoth Pharma (fictional)
**Version:** 1.0
**Status:** Approved for Tech Spec
**Requestor:** VP of Sales
**Date:** May 2026

---

## Business Context

A specialty pharmaceutical company has launched three oncology products
(Oncovex, Oncovex Plus, Oncovex-SC) and needs to measure sales force
effectiveness across 20 territories and 42 target physicians. The VP of
Sales needs a single view that connects rep call activity to prescription
outcomes to answer the fundamental question: which reps, territories,
and physician segments are driving the most revenue?

---

## Business Problem

Sales leadership currently tracks call activity in one system and
prescription data in another. There is no unified view that shows:
- Which reps are converting calls to prescriptions most effectively
- Which physician tiers are generating the most revenue per call
- Which products are gaining traction fastest after launch
- Which territories are underperforming relative to call investment

Without this view, the VP of Sales cannot make informed decisions about
territory realignment, rep coaching priorities, or physician targeting.

---

## Goals

1. Measure rep call-to-prescription conversion rates by territory
2. Identify highest value physicians by total prescriptions and revenue
3. Analyze product performance by therapeutic area and physician specialty
4. Show call activity effectiveness (revenue generated per call made)
5. Enable weekly self-service reporting without analyst involvement

---

## Decisions This Will Inform

- Territory realignment for next fiscal year
- Rep performance reviews and coaching priorities
- Physician targeting tier adjustments
- Product promotion budget allocation
- Identification of high-potential physicians not yet prescribing

---

## Metrics Defined

| Metric | Definition | Owner |
|--------|-----------|-------|
| Total Calls | COUNT of all sales calls made | Sales Ops |
| Total Prescriptions | COUNT of all prescriptions written | Sales Ops |
| Total Revenue | SUM of total_revenue_usd from prescriptions | Finance |
| New Patient Revenue | SUM of revenue where new_patient = true | Finance |
| Refill Revenue | SUM of revenue where prescription_type = Refill | Finance |
| Conversion Rate | Total Prescriptions / Total Calls as percentage | Sales Ops |
| Revenue Per Call | Total Revenue / Total Calls | Finance |
| Avg Discussion Minutes | AVG of discussion_minutes from calls | Sales Ops |
| Positive Call Rate | COUNT calls where outcome=Positive / Total Calls | Sales Ops |
| Calls Per Physician | Total Calls / Distinct Physicians Called | Sales Ops |

---

## Data Sources

| Source | Table | Description | Grain |
|--------|-------|-------------|-------|
| pharma_sales | seed_territories | Territory and rep master | One row per territory |
| pharma_sales | seed_physicians | Physician master | One row per physician |
| pharma_sales | seed_products | Product catalog | One row per product |
| pharma_sales | seed_sales_calls | Call activity | One row per call |
| pharma_sales | seed_prescriptions | Prescription outcomes | One row per prescription |

---

## Grain Definitions

| Model | Grain |
|-------|-------|
| Bronze models | One row per source record |
| silver_sales_activity | One row per call enriched with physician and territory detail |
| silver_prescription_activity | One row per prescription enriched with physician, product, and territory |
| gold_rep_performance | One row per sales rep |
| gold_physician_scorecard | One row per physician |
| gold_product_performance | One row per product |
| gold_territory_summary | One row per territory |

---

## Business Rules

| Rule | Definition |
|------|-----------|
| Active territory | Territory with at least one call in the period |
| Tier 1 physician | Physicians with tier = Tier 1 (highest prescribing potential) |
| Specialty drug | Products where is_specialty = true |
| New patient revenue | Prescriptions where new_patient = true |
| Refill revenue | Prescriptions where prescription_type = Refill |
| Positive call | Calls where call_outcome = Positive |
| Conversion | A physician who received a call AND wrote a prescription for the same product |

---

## Reporting Requirements

| Report | Consumer | Frequency |
|--------|---------|-----------|
| Rep Performance Scorecard | VP Sales | Weekly |
| Physician Scorecard | Regional Managers | Weekly |
| Product Performance | Marketing | Weekly |
| Territory Summary | Sales Ops | Weekly |

---

## Out of Scope

- Real-time call reporting (weekly batch sufficient)
- CRM integration (seed data only for this engagement)
- Managed care or payer data
- Sample inventory tracking beyond counts in call data

---

## Success Criteria

- VP Sales can identify top and bottom 5 reps by revenue per call
- Tier 1 physician conversion rate visible without manual calculation
- Product revenue trend visible by month
- All metrics reconcile to source CSV totals within 1%
