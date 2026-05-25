WITH orders AS (
    SELECT order_id, market_segment FROM {{ ref('sf10_silver_orders') }}
)

, lineitem AS (
    SELECT order_id, net_price, is_returned FROM {{ ref('sf10_silver_lineitem') }}
)

, joined AS (
    SELECT
        o.market_segment
        , o.order_id
        , li.net_price
        , li.is_returned
    FROM orders o
    JOIN lineitem li ON o.order_id = li.order_id
)

, aggregated AS (
    SELECT
        market_segment
        , COUNT(DISTINCT order_id)                      AS total_orders
        , SUM(net_price)                                AS total_revenue
        , SUM(net_price) / COUNT(DISTINCT order_id)    AS avg_order_value
        , COUNT(*)                                      AS total_items_sold
        , SUM(IFF(is_returned, 1, 0)) / COUNT(*)       AS return_rate
    FROM joined
    GROUP BY market_segment
)

SELECT * FROM aggregated
