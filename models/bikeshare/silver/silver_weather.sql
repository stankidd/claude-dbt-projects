WITH source AS (
    SELECT * FROM {{ ref('bronze_weather_hourly') }}
),

with_flags AS (
    SELECT
        observed_at,
        observed_hour,
        temp_celsius,
        COALESCE(precipitation_mm, 0)               AS precipitation_mm,
        COALESCE(snow_mm, 0)                        AS snow_mm,
        humidity_pct,
        wind_speed_kmh,
        condition_code,
        COALESCE(precipitation_mm, 0) > 0.1         AS is_raining,
        COALESCE(snow_mm, 0) > 0                    AS is_snowing,
        temp_celsius < 5                             AS is_cold
    FROM source
)

SELECT
    observed_at,
    observed_hour,
    temp_celsius,
    precipitation_mm,
    snow_mm,
    humidity_pct,
    wind_speed_kmh,
    condition_code,
    is_raining,
    is_snowing,
    is_cold,
    temp_celsius BETWEEN 10 AND 25 AND NOT is_raining               AS is_mild,
    CASE
        WHEN is_raining                                             THEN 'Rainy'
        WHEN is_snowing                                             THEN 'Snowy'
        WHEN is_cold                                                THEN 'Cold/Dry'
        WHEN temp_celsius BETWEEN 10 AND 25 AND NOT is_raining      THEN 'Mild/Clear'
        ELSE                                                             'Hot'
    END                                                             AS weather_category
FROM with_flags
