WITH source AS (
    SELECT * FROM {{ source('raw', 'trips_2023_q1') }}
)

SELECT
    CAST(ROW_NUMBER() OVER (ORDER BY starttime) AS VARCHAR)             AS trip_id,
    TO_TIMESTAMP_NTZ(CAST(starttime AS NUMBER) / 1000000 / 1000)       AS started_at,
    TO_TIMESTAMP_NTZ(CAST(stoptime AS NUMBER) / 1000000 / 1000)        AS ended_at,
    CAST(tripduration AS INTEGER)                                       AS trip_duration_seconds,
    CAST("start station id" AS VARCHAR)                                 AS start_station_id,
    CAST("start station name" AS VARCHAR)                               AS start_station_name,
    CAST("start station latitude" AS FLOAT)                             AS start_lat,
    CAST("start station longitude" AS FLOAT)                            AS start_lng,
    CAST("end station id" AS VARCHAR)                                   AS end_station_id,
    CAST("end station name" AS VARCHAR)                                 AS end_station_name,
    CAST("end station latitude" AS FLOAT)                               AS end_lat,
    CAST("end station longitude" AS FLOAT)                              AS end_lng,
    CAST(bikeid AS VARCHAR)                                             AS bike_id,
    usertype                                                            AS user_type,
    'classic_bike'                                                      AS rideable_type,
    'Q1'                                                                AS quarter
FROM source
