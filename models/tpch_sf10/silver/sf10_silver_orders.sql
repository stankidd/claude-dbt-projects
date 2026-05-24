WITH orders AS (
    SELECT * FROM {{ ref('sf10_bronze_orders') }}
)

, customers AS (
    SELECT * FROM {{ ref('sf10_bronze_customer') }}
)

, nations AS (
    SELECT * FROM {{ ref('sf10_bronze_nation') }}
)

, joined AS (
    SELECT
        o.order_id
        , o.customer_id
        , c.customer_name
        , c.market_segment
        , n.nation_name
        , o.order_status
        , o.order_date
        , o.order_priority
        , o.total_price
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN nations n ON c.nation_id = n.nation_id
)

SELECT * FROM joined
