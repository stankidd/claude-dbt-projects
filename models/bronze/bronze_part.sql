WITH source AS (
    SELECT * FROM {{ source('tpch', 'part') }}
)

, renamed AS (
    SELECT
        p_partkey       AS part_id
        , p_name        AS part_name
        , p_mfgr        AS manufacturer
        , p_brand       AS brand
        , p_type        AS part_type
        , p_size        AS size
        , p_container   AS container
        , p_retailprice AS retail_price
        , p_comment     AS part_comment
    FROM source
)

SELECT * FROM renamed
