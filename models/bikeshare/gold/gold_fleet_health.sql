WITH fleet AS (
    SELECT * FROM {{ ref('silver_bike_fleet') }}
),

trips AS (
    SELECT * FROM {{ ref('silver_trips') }}
),

bike_trips AS (
    SELECT
        bike_id,
        COUNT(*)                                                                AS total_trips,
        COUNT(CASE WHEN quarter = 'Q1' THEN 1 END)                             AS q1_trips,
        COUNT(CASE WHEN quarter = 'Q4' THEN 1 END)                             AS q4_trips
    FROM trips
    WHERE bike_id IS NOT NULL
    GROUP BY bike_id
)

SELECT
    f.bike_id,
    f.is_active,
    f.fleet_age_days,
    f.fleet_age_years,
    COALESCE(bt.total_trips, 0)                                                AS total_trips,
    COALESCE(bt.q1_trips, 0)                                                   AS q1_trips,
    COALESCE(bt.q4_trips, 0)                                                   AS q4_trips,
    CAST(COALESCE(bt.total_trips, 0) AS FLOAT)
        / NULLIF(f.fleet_age_days, 0)                                          AS trips_per_day,
    CASE
        WHEN f.fleet_age_years < 1  THEN 'New (<1yr)'
        WHEN f.fleet_age_years < 3  THEN 'Mid (1-3yr)'
        WHEN f.fleet_age_years < 5  THEN 'Aging (3-5yr)'
        ELSE                             'Old (5yr+)'
    END                                                                        AS age_category
FROM fleet AS f
LEFT JOIN bike_trips AS bt
    ON f.bike_id = bt.bike_id
