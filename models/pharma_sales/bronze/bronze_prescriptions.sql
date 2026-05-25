WITH source AS (
    SELECT * FROM {{ source('pharma_sales', 'seed_prescriptions') }}
)

SELECT
    rx_id
    , CAST(rx_date AS DATE) AS rx_date
    , physician_id
    , product_id
    , territory_id
    , CAST(quantity_units AS INTEGER) AS quantity_units
    , CAST(total_revenue_usd AS NUMERIC) AS total_revenue_usd
    , CAST(new_patient AS BOOLEAN) AS new_patient
    , prescription_type
FROM source
