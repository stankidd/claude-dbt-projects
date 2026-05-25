WITH calls AS (
    SELECT * FROM {{ ref('bronze_sales_calls') }}
)

, physicians AS (
    SELECT * FROM {{ ref('bronze_physicians') }}
)

, territories AS (
    SELECT * FROM {{ ref('bronze_territories') }}
)

, products AS (
    SELECT * FROM {{ ref('bronze_products') }}
)

SELECT
    c.call_id
    , c.call_date
    , c.rep_id
    , t.rep_name
    , c.territory_id
    , t.territory_name
    , t.region
    , t.district
    , c.physician_id
    , ph.physician_name
    , ph.specialty
    , ph.tier
    , c.product_id
    , p.product_name
    , p.therapeutic_area
    , p.is_specialty                        AS is_specialty_product
    , c.call_type
    , c.call_outcome
    , (c.call_outcome = 'Positive')         AS is_positive_call
    , c.samples_left
    , c.discussion_minutes
    , c.follow_up_required
FROM calls c
INNER JOIN physicians ph ON c.physician_id = ph.physician_id
INNER JOIN territories t  ON c.territory_id = t.territory_id
INNER JOIN products p     ON c.product_id   = p.product_id
