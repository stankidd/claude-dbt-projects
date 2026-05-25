WITH source AS (
    SELECT * FROM {{ source('pharma_sales', 'seed_physicians') }}
)

SELECT
    physician_id
    , physician_name
    , specialty
    , practice_name
    , city
    , state
    , territory_id
    , tier
    , CAST(years_in_practice AS INTEGER) AS years_in_practice
FROM source
