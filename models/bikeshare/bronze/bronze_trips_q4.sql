WITH source AS (
    SELECT * FROM {{ source('raw', 'trips_2023_q4') }}
),

converted AS (
    SELECT
        ride_id,
        rideable_type,
        TO_TIMESTAMP_NTZ(CAST(started_at AS NUMBER) / 1000000 / 1000)  AS started_at,
        TO_TIMESTAMP_NTZ(CAST(ended_at AS NUMBER) / 1000000 / 1000)    AS ended_at,
        CAST(start_station_id AS VARCHAR)                               AS start_station_id,
        start_station_name,
        CAST(end_station_id AS VARCHAR)                                 AS end_station_id,
        end_station_name,
        CAST(start_lat AS FLOAT)                                        AS start_lat,
        CAST(start_lng AS FLOAT)                                        AS start_lng,
        CAST(end_lat AS FLOAT)                                          AS end_lat,
        CAST(end_lng AS FLOAT)                                          AS end_lng,
        member_casual,
        CAST(bike_id AS VARCHAR)                                        AS bike_id
    FROM source
)

SELECT
    ride_id                                                             AS trip_id,
    started_at,
    ended_at,
    DATEDIFF('second', started_at, ended_at)                           AS trip_duration_seconds,
    start_station_id,
    start_station_name,
    start_lat,
    start_lng,
    end_station_id,
    end_station_name,
    end_lat,
    end_lng,
    bike_id,
    member_casual                                                       AS user_type,
    rideable_type,
    'Q4'                                                                AS quarter
FROM converted
