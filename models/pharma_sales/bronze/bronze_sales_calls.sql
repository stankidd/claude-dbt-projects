WITH source AS (
    SELECT * FROM {{ source('pharma_sales', 'seed_sales_calls') }}
)

SELECT
    call_id
    , CAST(call_date AS DATE) AS call_date
    , rep_id
    , territory_id
    , physician_id
    , product_id
    , call_type
    , call_outcome
    , CAST(samples_left AS INTEGER) AS samples_left
    , CAST(discussion_minutes AS INTEGER) AS discussion_minutes
    , CAST(follow_up_required AS BOOLEAN) AS follow_up_required
FROM source
