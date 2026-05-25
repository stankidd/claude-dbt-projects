WITH call_metrics AS (
    SELECT
        rep_id
        , MAX(rep_name)                                 AS rep_name
        , MAX(territory_id)                             AS territory_id
        , MAX(territory_name)                           AS territory_name
        , MAX(region)                                   AS region
        , MAX(district)                                 AS district
        , COUNT(*)                                      AS total_calls
        , SUM(IFF(is_positive_call, 1, 0))             AS positive_calls
        , COUNT(DISTINCT physician_id)                  AS distinct_physicians_called
        , AVG(CAST(discussion_minutes AS FLOAT))        AS avg_discussion_minutes
    FROM {{ ref('silver_sales_activity') }}
    GROUP BY rep_id
)

, rx_metrics AS (
    SELECT
        rep_id
        , COUNT(*)                                      AS total_prescriptions
        , SUM(total_revenue_usd)                        AS total_revenue
        , SUM(CASE WHEN is_new_patient THEN total_revenue_usd ELSE 0 END)
                                                        AS new_patient_revenue
        , SUM(CASE WHEN is_refill THEN total_revenue_usd ELSE 0 END)
                                                        AS refill_revenue
    FROM {{ ref('silver_prescription_activity') }}
    GROUP BY rep_id
)

, joined AS (
    SELECT
        c.rep_id
        , c.rep_name
        , c.territory_id
        , c.territory_name
        , c.region
        , c.district
        , c.total_calls
        , COALESCE(rx.total_prescriptions, 0)           AS total_prescriptions
        , COALESCE(rx.total_revenue, 0)                 AS total_revenue
        , COALESCE(rx.new_patient_revenue, 0)           AS new_patient_revenue
        , COALESCE(rx.refill_revenue, 0)                AS refill_revenue
        , c.positive_calls
        , c.distinct_physicians_called
        , c.avg_discussion_minutes
    FROM call_metrics c
    LEFT JOIN rx_metrics rx ON c.rep_id = rx.rep_id
)

SELECT
    rep_id
    , rep_name
    , territory_id
    , territory_name
    , region
    , district
    , total_calls
    , total_prescriptions
    , total_revenue
    , new_patient_revenue
    , refill_revenue
    , positive_calls
    , distinct_physicians_called
    , avg_discussion_minutes
    , CAST(total_prescriptions AS FLOAT) / NULLIF(total_calls, 0)           AS conversion_rate
    , total_revenue / NULLIF(total_calls, 0)                                AS revenue_per_call
    , CAST(positive_calls AS FLOAT) / NULLIF(total_calls, 0)               AS positive_call_rate
    , CAST(total_calls AS FLOAT) / NULLIF(distinct_physicians_called, 0)   AS calls_per_physician
FROM joined
