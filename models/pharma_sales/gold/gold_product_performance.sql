WITH all_products AS (
    SELECT * FROM {{ ref('bronze_products') }}
)

, call_metrics AS (
    SELECT
        product_id
        , COUNT(*)          AS total_calls
    FROM {{ ref('silver_sales_activity') }}
    GROUP BY product_id
)

, rx_metrics AS (
    SELECT
        product_id
        , COUNT(*)                                      AS total_prescriptions
        , SUM(total_revenue_usd)                        AS total_revenue
        , SUM(CASE WHEN is_new_patient THEN total_revenue_usd ELSE 0 END)
                                                        AS new_patient_revenue
        , SUM(CASE WHEN is_refill THEN total_revenue_usd ELSE 0 END)
                                                        AS refill_revenue
    FROM {{ ref('silver_prescription_activity') }}
    GROUP BY product_id
)

, joined AS (
    SELECT
        p.product_id
        , p.product_name
        , p.therapeutic_area
        , p.drug_class
        , p.is_specialty                                AS is_specialty_product
        , p.launch_date
        , COALESCE(c.total_calls, 0)                    AS total_calls
        , COALESCE(rx.total_prescriptions, 0)           AS total_prescriptions
        , COALESCE(rx.total_revenue, 0)                 AS total_revenue
        , COALESCE(rx.new_patient_revenue, 0)           AS new_patient_revenue
        , COALESCE(rx.refill_revenue, 0)                AS refill_revenue
    FROM all_products p
    LEFT JOIN call_metrics c  ON p.product_id = c.product_id
    LEFT JOIN rx_metrics rx   ON p.product_id = rx.product_id
)

SELECT
    product_id
    , product_name
    , therapeutic_area
    , drug_class
    , is_specialty_product
    , launch_date
    , total_calls
    , total_prescriptions
    , total_revenue
    , new_patient_revenue
    , refill_revenue
    , CAST(total_prescriptions AS FLOAT) / NULLIF(total_calls, 0)   AS conversion_rate
FROM joined
