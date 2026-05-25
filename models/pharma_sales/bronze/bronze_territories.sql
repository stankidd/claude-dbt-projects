WITH source AS (
    SELECT * FROM {{ source('pharma_sales', 'seed_territories') }}
)

SELECT
    territory_id
    , territory_name
    , region
    , district
    , rep_id
    , rep_name
    , CAST(rep_hire_date AS DATE) AS rep_hire_date
FROM source
