WITH lineitem AS (
    SELECT
        part_type
        , net_price
        , quantity
        , discount
        , is_returned
    FROM {{ ref('sf10_silver_lineitem') }}
)

, aggregated AS (
    SELECT
        part_type
        , SUM(net_price)                        AS total_revenue
        , SUM(quantity)                         AS total_quantity
        , COUNT(*)                              AS total_line_items
        , AVG(discount)                         AS avg_discount
        , SUM(IFF(is_returned, 1, 0)) / COUNT(*) AS return_rate
    FROM lineitem
    GROUP BY part_type
)

SELECT * FROM aggregated
