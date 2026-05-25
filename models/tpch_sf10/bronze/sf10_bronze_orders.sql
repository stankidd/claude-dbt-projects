WITH source AS (
    SELECT * FROM {{ source('tpch_sf10', 'orders') }}
)

, renamed AS (
    SELECT
        o_orderkey        AS order_id
        , o_custkey       AS customer_id
        , o_orderstatus   AS order_status
        , o_totalprice    AS total_price
        , o_orderdate     AS order_date
        , o_orderpriority AS order_priority
        , o_shippriority  AS ship_priority
        , o_comment       AS order_comment
    FROM source
)

SELECT * FROM renamed
