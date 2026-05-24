WITH source AS (
    SELECT * FROM {{ source('tpch', 'nation') }}
)

, renamed AS (
    SELECT
        n_nationkey     AS nation_id
        , n_name        AS nation_name
        , n_regionkey   AS region_id
        , n_comment     AS nation_comment
    FROM source
)

SELECT * FROM renamed
