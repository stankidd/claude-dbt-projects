WITH lineitem AS (
    SELECT * FROM {{ ref('sf10_bronze_lineitem') }}
)

, suppliers AS (
    SELECT * FROM {{ ref('sf10_bronze_supplier') }}
)

, nations AS (
    SELECT * FROM {{ ref('sf10_bronze_nation') }}
)

, parts AS (
    SELECT * FROM {{ ref('sf10_bronze_part') }}
)

, joined AS (
    SELECT
        li.order_id
        , li.line_number
        , li.supplier_id
        , s.supplier_name
        , n.nation_name
        , li.part_id
        , p.part_type
        , li.quantity
        , li.extended_price
        , li.discount
        , li.tax
        , li.extended_price * (1 - li.discount) * (1 + li.tax)     AS net_price
        , (li.return_flag = 'R')                                    AS is_returned
        , (li.ship_date > li.commit_date)                           AS is_late_shipment
        , CASE
            WHEN li.ship_date > li.commit_date
                THEN DATEDIFF('day', li.commit_date, li.ship_date)
            ELSE NULL
          END                                                        AS days_late
        , li.ship_date
        , li.commit_date
    FROM lineitem li
    JOIN suppliers s  ON li.supplier_id = s.supplier_id
    JOIN nations n    ON s.nation_id    = n.nation_id
    JOIN parts p      ON li.part_id     = p.part_id
)

SELECT * FROM joined
