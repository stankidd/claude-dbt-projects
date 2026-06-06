WITH trips AS (
    SELECT * FROM {{ ref('silver_trips') }}
),

stations_raw AS (
    SELECT * FROM {{ ref('silver_stations') }}
),

-- Multiple stations share the same station_id_int (different decimal suffixes).
-- Pick the one with the highest capacity as the canonical record.
stations AS (
    SELECT *
    FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY station_id_int
                ORDER BY capacity DESC NULLS LAST
            ) AS _rn
        FROM stations_raw
    )
    WHERE _rn = 1
),

departures AS (
    SELECT
        start_station_id_int                                                    AS station_id_int,
        COUNT(*)                                                                AS total_trips,
        COUNT(CASE WHEN quarter = 'Q1' THEN 1 END)                             AS q1_trips,
        COUNT(CASE WHEN quarter = 'Q4' THEN 1 END)                             AS q4_trips,
        COUNT(CASE WHEN is_weekday THEN 1 END)                                 AS weekday_trips,
        COUNT(CASE WHEN is_weekend THEN 1 END)                                 AS weekend_trips,
        COUNT(CASE WHEN is_am_peak THEN 1 END)                                 AS am_peak_trips,
        COUNT(CASE WHEN is_pm_peak THEN 1 END)                                 AS pm_peak_trips,
        COUNT(CASE WHEN is_member THEN 1 END)                                  AS member_trips,
        COUNT(CASE WHEN NOT is_member THEN 1 END)                              AS casual_trips
    FROM trips
    WHERE start_station_id_int IS NOT NULL
    GROUP BY start_station_id_int
),

arrivals AS (
    SELECT
        end_station_id_int                                                      AS station_id_int,
        COUNT(*)                                                                AS trips_arrived
    FROM trips
    WHERE end_station_id_int IS NOT NULL
    GROUP BY end_station_id_int
),

station_metrics AS (
    SELECT
        d.station_id_int,
        d.total_trips,
        d.q1_trips,
        d.q4_trips,
        d.weekday_trips,
        d.weekend_trips,
        d.am_peak_trips,
        d.pm_peak_trips,
        d.member_trips,
        d.casual_trips,
        d.total_trips - COALESCE(a.trips_arrived, 0)                           AS net_flow,
        CAST(d.weekday_trips AS FLOAT) / NULLIF(d.weekend_trips, 0)            AS weekday_weekend_ratio,
        CAST(d.am_peak_trips + d.pm_peak_trips AS FLOAT) / NULLIF(d.total_trips, 0)
                                                                                AS peak_hour_pct,
        CAST(d.member_trips AS FLOAT) / NULLIF(d.total_trips, 0)               AS member_rate
    FROM departures AS d
    LEFT JOIN arrivals AS a
        ON d.station_id_int = a.station_id_int
),

classified AS (
    SELECT
        sm.station_id_int,
        s.station_name,
        s.lat,
        s.lng,
        s.capacity,
        sm.total_trips,
        sm.q1_trips,
        sm.q4_trips,
        sm.weekday_trips,
        sm.weekend_trips,
        sm.am_peak_trips,
        sm.pm_peak_trips,
        sm.member_trips,
        sm.casual_trips,
        sm.weekday_weekend_ratio,
        sm.peak_hour_pct,
        sm.member_rate,
        sm.net_flow,
        CASE
            WHEN sm.weekday_weekend_ratio > 1.5 AND sm.peak_hour_pct > 0.25
                THEN 'Commuter'
            ELSE 'Leisure'
        END                                                                     AS station_type,
        CASE
            WHEN CAST(ABS(sm.q1_trips - sm.q4_trips) AS FLOAT)
                 / NULLIF(GREATEST(sm.q1_trips, sm.q4_trips), 0) < 0.2
                THEN 'Stable'
            ELSE 'Seasonal'
        END                                                                     AS seasonal_stability
    FROM station_metrics AS sm
    LEFT JOIN stations AS s
        ON sm.station_id_int = s.station_id_int
)

SELECT * FROM classified
