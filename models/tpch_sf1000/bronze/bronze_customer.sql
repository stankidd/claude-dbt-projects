WITH source AS (
    SELECT * FROM {{ source('tpch_sf1000', 'customer') }}
)

, renamed AS (
    SELECT
        c_custkey       AS customer_id
        , c_name        AS customer_name
        , c_address     AS address
        , c_nationkey   AS nation_id
        , c_phone       AS phone
        , c_acctbal     AS account_balance
        , c_mktsegment  AS market_segment
        , c_comment     AS customer_comment
    FROM source
)

SELECT * FROM renamed
