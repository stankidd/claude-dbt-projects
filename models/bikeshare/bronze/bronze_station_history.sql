WITH source AS (
    SELECT * FROM {{ source('raw', 'station_history') }}
)

SELECT
    CAST(previous_station_id AS VARCHAR)                               AS previous_station_id,
    REPLACE(CAST(previous_station_id AS VARCHAR), 'HIST_', '')         AS previous_station_id_clean,
    CAST(current_station_id AS VARCHAR)                                AS current_station_id,
    SPLIT_PART(CAST(current_station_id AS VARCHAR), '.', 1)            AS current_station_id_int,
    CAST(station_name AS VARCHAR)                                      AS station_name,
    CAST(lat AS FLOAT)                                                 AS lat,
    CAST(lng AS FLOAT)                                                 AS lng,
    CAST(retired_at AS DATE)                                           AS retired_at
FROM source
