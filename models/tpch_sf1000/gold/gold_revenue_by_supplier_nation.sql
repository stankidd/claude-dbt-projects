WITH lineitem AS (
    SELECT
        supplier_nation
        , net_price
        , quantity
        , discount
        , is_late_shipment
    FROM {{ ref('silver_lineitem') }}
)

, aggregated AS (
    SELECT
        supplier_nation
        , SUM(net_price)                                    AS total_revenue
        , SUM(quantity)                                     AS total_quantity
        , COUNT(*)                                          AS total_line_items
        , AVG(discount)                                     AS avg_discount
        , SUM(IFF(is_late_shipment, 1, 0)) / COUNT(*)      AS late_shipment_rate
    FROM lineitem
    GROUP BY supplier_nation
)

SELECT * FROM aggregated
