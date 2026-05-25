WITH call_metrics AS (
    SELECT
        physician_id
        , MAX(physician_name)                           AS physician_name
        , MAX(specialty)                                AS specialty
        , MAX(tier)                                     AS tier
        , MAX(territory_id)                             AS territory_id
        , MAX(territory_name)                           AS territory_name
        , COUNT(*)                                      AS total_calls
        , SUM(IFF(is_positive_call, 1, 0))             AS positive_calls
        , AVG(CAST(discussion_minutes AS FLOAT))        AS avg_discussion_minutes
    FROM {{ ref('silver_sales_activity') }}
    GROUP BY physician_id
)

, rx_metrics AS (
    SELECT
        physician_id
        , COUNT(*)                                      AS total_prescriptions
        , SUM(total_revenue_usd)                        AS total_revenue
        , SUM(CASE WHEN is_new_patient THEN total_revenue_usd ELSE 0 END)
                                                        AS new_patient_revenue
        , SUM(CASE WHEN is_refill THEN total_revenue_usd ELSE 0 END)
                                                        AS refill_revenue
    FROM {{ ref('silver_prescription_activity') }}
    GROUP BY physician_id
)

, joined AS (
    SELECT
        c.physician_id
        , c.physician_name
        , c.specialty
        , c.tier
        , c.territory_id
        , c.territory_name
        , c.total_calls
        , COALESCE(rx.total_prescriptions, 0)           AS total_prescriptions
        , COALESCE(rx.total_revenue, 0)                 AS total_revenue
        , COALESCE(rx.new_patient_revenue, 0)           AS new_patient_revenue
        , COALESCE(rx.refill_revenue, 0)                AS refill_revenue
        , c.positive_calls
        , c.avg_discussion_minutes
    FROM call_metrics c
    LEFT JOIN rx_metrics rx ON c.physician_id = rx.physician_id
)

SELECT
    physician_id
    , physician_name
    , specialty
    , tier
    , territory_id
    , territory_name
    , total_calls
    , total_prescriptions
    , total_revenue
    , new_patient_revenue
    , refill_revenue
    , avg_discussion_minutes
    , CAST(positive_calls AS FLOAT) / NULLIF(total_calls, 0)               AS positive_call_rate
    , CAST(total_prescriptions AS FLOAT) / NULLIF(total_calls, 0)          AS conversion_rate
FROM joined
