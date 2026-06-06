WITH trips AS (
    SELECT * FROM {{ ref('silver_trips') }}
),

weather AS (
    SELECT * FROM {{ ref('silver_weather') }}
),

hourly_trips AS (
    SELECT
        DATE_TRUNC('hour', started_at)                                          AS trip_hour,
        DATE(started_at)                                                        AS trip_date,
        HOUR(started_at)                                                        AS hour_of_day,
        quarter,
        COUNT(*)                                                                AS trip_count,
        COUNT(CASE WHEN is_member THEN 1 END)                                  AS member_trip_count
    FROM trips
    GROUP BY
        DATE_TRUNC('hour', started_at),
        DATE(started_at),
        HOUR(started_at),
        quarter
)

SELECT
    ht.trip_hour,
    ht.trip_date,
    ht.hour_of_day,
    ht.quarter,
    ht.trip_count,
    ht.member_trip_count,
    w.temp_celsius,
    w.precipitation_mm,
    w.is_raining,
    w.is_cold,
    w.is_mild,
    w.weather_category
FROM hourly_trips AS ht
LEFT JOIN weather AS w
    ON ht.trip_hour = w.observed_hour
