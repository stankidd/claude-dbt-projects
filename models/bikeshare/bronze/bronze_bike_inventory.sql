WITH source AS (
    SELECT * FROM {{ source('raw', 'bike_inventory') }}
)

SELECT
    CAST(bike_id AS VARCHAR)                                            AS bike_id,
    CAST(event_type AS VARCHAR)                                         AS event_type,
    CAST(event_date AS DATE)                                            AS event_date,
    CAST(notes AS VARCHAR)                                              AS notes
FROM source
