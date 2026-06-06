WITH source AS (
    SELECT * FROM {{ ref('bronze_bike_inventory') }}
),

fleet_events AS (
    SELECT
        bike_id,
        MIN(CASE WHEN event_type = 'added' THEN event_date END)     AS first_added_date,
        MAX(CASE WHEN event_type = 'retired' THEN event_date END)   AS retired_date
    FROM source
    GROUP BY bike_id
)

SELECT
    bike_id,
    first_added_date,
    retired_date,
    retired_date IS NULL                                            AS is_active,
    DATEDIFF('day', first_added_date, CURRENT_DATE)                AS fleet_age_days,
    DATEDIFF('day', first_added_date, CURRENT_DATE) / 365.0        AS fleet_age_years
FROM fleet_events
