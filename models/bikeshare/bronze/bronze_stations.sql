WITH source AS (
    SELECT * FROM {{ source('raw', 'stations') }}
)

SELECT
    CAST(station_id AS VARCHAR)                                         AS station_id,
    SPLIT_PART(CAST(station_id AS VARCHAR), '.', 1)                    AS station_id_int,
    CAST(station_name AS VARCHAR)                                       AS station_name,
    CAST(lat AS FLOAT)                                                  AS lat,
    CAST(lng AS FLOAT)                                                  AS lng,
    CAST(capacity AS INTEGER)                                           AS capacity
FROM source
