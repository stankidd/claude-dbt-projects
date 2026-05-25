WITH supplier_performance AS (
    SELECT * FROM {{ ref('sf10_silver_supplier_performance') }}
)

, aggregated AS (
    SELECT
        nation_name
        , COUNT(DISTINCT supplier_id)                      AS supplier_count
        , SUM(net_price)                                   AS total_revenue
        , COUNT(*)                                         AS total_line_items
        , SUM(quantity)                                    AS total_quantity
        , AVG(discount)                                    AS avg_discount_rate
        , SUM(IFF(is_late_shipment, 1, 0))                AS late_shipment_count
        , SUM(IFF(is_late_shipment, 1, 0)) / COUNT(*)     AS late_shipment_rate
        , AVG(days_late)                                   AS avg_days_late
        , SUM(IFF(is_returned, 1, 0)) / COUNT(*)          AS return_rate
    FROM supplier_performance
    GROUP BY nation_name
)

SELECT * FROM aggregated
