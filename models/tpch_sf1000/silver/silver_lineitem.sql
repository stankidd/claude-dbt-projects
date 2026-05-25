WITH lineitem AS (
    SELECT * FROM {{ ref('bronze_lineitem') }}
)

, parts AS (
    SELECT * FROM {{ ref('bronze_part') }}
)

, suppliers AS (
    SELECT * FROM {{ ref('bronze_supplier') }}
)

, nations AS (
    SELECT * FROM {{ ref('bronze_nation') }}
)

, joined AS (
    SELECT
        li.order_id
        , li.line_number
        , li.part_id
        , p.part_name
        , p.part_type
        , p.brand
        , li.supplier_id
        , s.supplier_name
        , n.nation_name                                             AS supplier_nation
        , li.quantity
        , li.extended_price
        , li.discount
        , li.extended_price * (1 - li.discount)                    AS discounted_price
        , li.extended_price * (1 - li.discount) * (1 + li.tax)    AS net_price
        , (li.return_flag = 'R')                                   AS is_returned
        , (li.ship_date > li.commit_date)                          AS is_late_shipment
        , li.ship_date
        , li.ship_mode
    FROM lineitem li
    JOIN parts p
        ON li.part_id = p.part_id
    JOIN suppliers s
        ON li.supplier_id = s.supplier_id
    JOIN nations n
        ON s.nation_id = n.nation_id
)

SELECT * FROM joined
