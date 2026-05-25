WITH prescriptions AS (
    SELECT * FROM {{ ref('bronze_prescriptions') }}
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
    rx.rx_id
    , rx.rx_date
    , t.rep_id
    , t.rep_name
    , rx.territory_id
    , t.territory_name
    , t.region
    , t.district
    , rx.physician_id
    , ph.physician_name
    , ph.specialty
    , ph.tier
    , rx.product_id
    , p.product_name
    , p.therapeutic_area
    , p.is_specialty                            AS is_specialty_product
    , rx.quantity_units
    , rx.total_revenue_usd
    , rx.prescription_type
    , rx.new_patient                            AS is_new_patient
    , (rx.prescription_type = 'Refill')         AS is_refill
FROM prescriptions rx
INNER JOIN physicians ph ON rx.physician_id = ph.physician_id
INNER JOIN territories t  ON rx.territory_id = t.territory_id
INNER JOIN products p     ON rx.product_id   = p.product_id
