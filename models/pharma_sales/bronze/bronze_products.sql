WITH source AS (
    SELECT * FROM {{ source('pharma_sales', 'seed_products') }}
)

SELECT
    product_id
    , product_name
    , generic_name
    , therapeutic_area
    , drug_class
    , formulation
    , dosage_strength
    , CAST(list_price_usd AS NUMERIC) AS list_price_usd
    , CAST(launch_date AS DATE)       AS launch_date
    , CAST(is_specialty AS BOOLEAN)   AS is_specialty
FROM source
