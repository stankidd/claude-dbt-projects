WITH q1 AS (
    SELECT * FROM {{ ref('bronze_trips_q1') }}
),

q4 AS (
    SELECT * FROM {{ ref('bronze_trips_q4') }}
),

unioned AS (
    SELECT
        trip_id,
        started_at,
        ended_at,
        trip_duration_seconds,
        start_station_id,
        start_station_name,
        start_lat,
        start_lng,
        end_station_id,
        end_station_name,
        end_lat,
        end_lng,
        bike_id,
        user_type,
        rideable_type,
        quarter
    FROM q1

    UNION ALL

    SELECT
        trip_id,
        started_at,
        ended_at,
        trip_duration_seconds,
        start_station_id,
        start_station_name,
        start_lat,
        start_lng,
        end_station_id,
        end_station_name,
        end_lat,
        end_lng,
        bike_id,
        user_type,
        rideable_type,
        quarter
    FROM q4
),

deduped AS (
    -- Q4 source has duplicate ride_ids; keep first occurrence per quarter+trip_id
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY quarter, trip_id ORDER BY started_at) AS _row_num
    FROM unioned
),

valid AS (
    SELECT *
    FROM deduped
    WHERE trip_duration_seconds BETWEEN 60 AND 86400
      AND _row_num = 1
)

SELECT
    trip_id,
    started_at,
    ended_at,
    DATE(started_at)                                                AS trip_date,
    HOUR(started_at)                                                AS trip_hour,
    DAYOFWEEK(started_at)                                           AS trip_dow,
    DAYOFWEEK(started_at) NOT IN (0, 6)                             AS is_weekday,
    DAYOFWEEK(started_at) IN (0, 6)                                 AS is_weekend,
    HOUR(started_at) BETWEEN 7 AND 9                                AS is_am_peak,
    HOUR(started_at) BETWEEN 17 AND 19                              AS is_pm_peak,
    trip_duration_seconds,
    trip_duration_seconds / 60.0                                    AS trip_duration_minutes,
    start_station_id,
    SPLIT_PART(start_station_id, '.', 1)                            AS start_station_id_int,
    end_station_id,
    SPLIT_PART(end_station_id, '.', 1)                              AS end_station_id_int,
    start_station_name,
    end_station_name,
    start_lat,
    start_lng,
    bike_id,
    user_type,
    user_type IN ('Subscriber', 'member')                           AS is_member,
    rideable_type,
    quarter
FROM valid
