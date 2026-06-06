WITH stations AS (
    SELECT * FROM {{ ref('bronze_stations') }}
),

history AS (
    SELECT DISTINCT current_station_id_int
    FROM {{ ref('bronze_station_history') }}
)

SELECT
    s.station_id,
    s.station_id_int,
    s.station_name,
    s.lat,
    s.lng,
    s.capacity,
    h.current_station_id_int IS NOT NULL                            AS has_history
FROM stations AS s
LEFT JOIN history AS h
    ON s.station_id_int = h.current_station_id_int
