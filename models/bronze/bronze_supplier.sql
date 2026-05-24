WITH source AS (
    SELECT * FROM {{ source('tpch', 'supplier') }}
)

, renamed AS (
    SELECT
        s_suppkey       AS supplier_id
        , s_name        AS supplier_name
        , s_address     AS address
        , s_nationkey   AS nation_id
        , s_phone       AS phone
        , s_acctbal     AS account_balance
        , s_comment     AS supplier_comment
    FROM source
)

SELECT * FROM renamed
