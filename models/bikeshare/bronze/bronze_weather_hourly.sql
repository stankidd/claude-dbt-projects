WITH source AS (
    SELECT * FROM {{ source('raw', 'weather_hourly') }}
),

converted AS (
    SELECT
        TO_TIMESTAMP_NTZ(CAST(observed_at_utc AS NUMBER) / 1000000 / 1000) AS observed_at,
        CAST(temp AS FLOAT)                                                  AS temp_celsius,
        CAST(dwpt AS FLOAT)                                                  AS dewpoint,
        CAST(rhum AS FLOAT)                                                  AS humidity_pct,
        CAST(prcp AS FLOAT)                                                  AS precipitation_mm,
        CAST(snow AS FLOAT)                                                  AS snow_mm,
        CAST(wdir AS FLOAT)                                                  AS wind_dir,
        CAST(wspd AS FLOAT)                                                  AS wind_speed_kmh,
        CAST(pres AS FLOAT)                                                  AS pressure_hpa,
        CAST(coco AS INTEGER)                                                AS condition_code
    FROM source
)

SELECT
    observed_at,
    DATE_TRUNC('hour', observed_at)                                     AS observed_hour,
    temp_celsius,
    dewpoint,
    humidity_pct,
    precipitation_mm,
    snow_mm,
    wind_dir,
    wind_speed_kmh,
    pressure_hpa,
    condition_code
FROM converted
