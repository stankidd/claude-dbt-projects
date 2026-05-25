@"
# TPCH Order Analytics — Technical Specification

## Business Context
Build an order analytics pipeline using the Snowflake TPCH sample dataset
to produce revenue and performance metrics by customer segment, supplier
nation, and part type.

## Source Data
Database: SNOWFLAKE_SAMPLE_DATA
Schema: TPCH_SF1000

## Architecture
SNOWFLAKE_SAMPLE_DATA.TPCH_SF1000 (source)
  -> Bronze (parse and rename)
  -> Silver (clean, join, business logic)
  -> Gold (aggregated metrics)

---

## Bronze Models

### bronze_orders
- Source: TPCH_SF1000.ORDERS
- Materialization: view
- Grain: one row per order
- Purpose: parse and rename raw orders data

| Target Column      | Source Column   | Type    |
|--------------------|----------------|---------|
| order_id           | O_ORDERKEY     | integer |
| customer_id        | O_CUSTKEY      | integer |
| order_status       | O_ORDERSTATUS  | varchar |
| total_price        | O_TOTALPRICE   | numeric |
| order_date         | O_ORDERDATE    | date    |
| order_priority     | O_ORDERPRIORITY| varchar |
| ship_priority      | O_SHIPPRIORITY | integer |
| order_comment      | O_COMMENT      | varchar |

Tests:
- order_id: unique, not_null
- customer_id: not_null
- order_status: accepted_values ['O', 'F', 'P']

---

### bronze_lineitem
- Source: TPCH_SF1000.LINEITEM
- Materialization: view
- Grain: one row per order line item
- Purpose: parse and rename raw line item data

| Target Column        | Source Column      | Type    |
|----------------------|--------------------|---------|
| order_id             | L_ORDERKEY         | integer |
| part_id              | L_PARTKEY          | integer |
| supplier_id          | L_SUPPKEY          | integer |
| line_number          | L_LINENUMBER       | integer |
| quantity             | L_QUANTITY         | numeric |
| extended_price       | L_EXTENDEDPRICE    | numeric |
| discount             | L_DISCOUNT         | numeric |
| tax                  | L_TAX              | numeric |
| return_flag          | L_RETURNFLAG       | varchar |
| line_status          | L_LINESTATUS       | varchar |
| ship_date            | L_SHIPDATE         | date    |
| commit_date          | L_COMMITDATE       | date    |
| receipt_date         | L_RECEIPTDATE      | date    |
| ship_mode            | L_SHIPMODE         | varchar |
| line_comment         | L_COMMENT          | varchar |

Tests:
- order_id: not_null
- line_number: not_null
- order_id + line_number: unique composite key
- return_flag: accepted_values ['R', 'A', 'N']
- line_status: accepted_values ['O', 'F']

---

### bronze_customer
- Source: TPCH_SF1000.CUSTOMER
- Materialization: view
- Grain: one row per customer

| Target Column      | Source Column   | Type    |
|--------------------|----------------|---------|
| customer_id        | C_CUSTKEY      | integer |
| customer_name      | C_NAME         | varchar |
| address            | C_ADDRESS      | varchar |
| nation_id          | C_NATIONKEY    | integer |
| phone              | C_PHONE        | varchar |
| account_balance    | C_ACCTBAL      | numeric |
| market_segment     | C_MKTSEGMENT   | varchar |
| customer_comment   | C_COMMENT      | varchar |

Tests:
- customer_id: unique, not_null
- nation_id: not_null
- market_segment: accepted_values ['AUTOMOBILE','BUILDING','FURNITURE','MACHINERY','HOUSEHOLD']

---

### bronze_supplier
- Source: TPCH_SF1000.SUPPLIER
- Materialization: view
- Grain: one row per supplier

| Target Column      | Source Column   | Type    |
|--------------------|----------------|---------|
| supplier_id        | S_SUPPKEY      | integer |
| supplier_name      | S_NAME         | varchar |
| address            | S_ADDRESS      | varchar |
| nation_id          | S_NATIONKEY    | integer |
| phone              | S_PHONE        | varchar |
| account_balance    | S_ACCTBAL      | numeric |
| supplier_comment   | S_COMMENT      | varchar |

Tests:
- supplier_id: unique, not_null
- nation_id: not_null

---

### bronze_nation
- Source: TPCH_SF1000.NATION
- Materialization: view
- Grain: one row per nation

| Target Column   | Source Column  | Type    |
|-----------------|---------------|---------|
| nation_id       | N_NATIONKEY   | integer |
| nation_name     | N_NAME        | varchar |
| region_id       | N_REGIONKEY   | integer |
| nation_comment  | N_COMMENT     | varchar |

Tests:
- nation_id: unique, not_null

---

### bronze_part
- Source: TPCH_SF1000.PART
- Materialization: view
- Grain: one row per part

| Target Column   | Source Column  | Type    |
|-----------------|---------------|---------|
| part_id         | P_PARTKEY     | integer |
| part_name       | P_NAME        | varchar |
| manufacturer    | P_MFGR        | varchar |
| brand           | P_BRAND       | varchar |
| part_type       | P_TYPE        | varchar |
| size            | P_SIZE        | integer |
| container       | P_CONTAINER   | varchar |
| retail_price    | P_RETAILPRICE | numeric |
| part_comment    | P_COMMENT     | varchar |

Tests:
- part_id: unique, not_null

---

## Silver Models

### silver_orders
- Depends on: bronze_orders, bronze_customer, bronze_nation
- Materialization: table
- Grain: one row per order
- Purpose: enrich orders with customer and nation details

Key joins:
- bronze_orders JOIN bronze_customer ON customer_id
- bronze_customer JOIN bronze_nation ON nation_id

Key transformations:
- Calculate discounted_price: extended_price * (1 - discount)
- Derive is_returned: return_flag = 'R'
- Derive is_late_shipment: ship_date > commit_date

| Column             | Type    | Logic                              |
|--------------------|---------|------------------------------------|
| order_id           | integer | from bronze_orders                 |
| customer_id        | integer | from bronze_orders                 |
| customer_name      | varchar | from bronze_customer               |
| market_segment     | varchar | from bronze_customer               |
| nation_name        | varchar | from bronze_nation                 |
| order_status       | varchar | from bronze_orders                 |
| order_date         | date    | from bronze_orders                 |
| order_priority     | varchar | from bronze_orders                 |
| total_price        | numeric | from bronze_orders                 |

Tests:
- order_id: unique, not_null
- customer_id: not_null
- market_segment: not_null

---

### silver_lineitem
- Depends on: bronze_lineitem, bronze_part, bronze_supplier, bronze_nation
- Materialization: table
- Grain: one row per line item
- Purpose: enrich line items with part, supplier, and nation details

Key joins:
- bronze_lineitem JOIN bronze_part ON part_id
- bronze_lineitem JOIN bronze_supplier ON supplier_id
- bronze_supplier JOIN bronze_nation ON nation_id

Key transformations:
- Calculate discounted_price: extended_price * (1 - discount)
- Calculate net_price: discounted_price * (1 + tax)
- Derive is_returned: return_flag = 'R'
- Derive is_late_shipment: ship_date > commit_date

| Column             | Type    | Logic                                    |
|--------------------|---------|------------------------------------------|
| order_id           | integer | from bronze_lineitem                     |
| line_number        | integer | from bronze_lineitem                     |
| part_id            | integer | from bronze_lineitem                     |
| part_name          | varchar | from bronze_part                         |
| part_type          | varchar | from bronze_part                         |
| brand              | varchar | from bronze_part                         |
| supplier_id        | integer | from bronze_lineitem                     |
| supplier_name      | varchar | from bronze_supplier                     |
| supplier_nation    | varchar | from bronze_nation                       |
| quantity           | numeric | from bronze_lineitem                     |
| extended_price     | numeric | from bronze_lineitem                     |
| discount           | numeric | from bronze_lineitem                     |
| discounted_price   | numeric | extended_price * (1 - discount)          |
| net_price          | numeric | discounted_price * (1 + tax)             |
| is_returned        | boolean | return_flag = 'R'                        |
| is_late_shipment   | boolean | ship_date > commit_date                  |
| ship_date          | date    | from bronze_lineitem                     |
| ship_mode          | varchar | from bronze_lineitem                     |

Tests:
- order_id: not_null
- line_number: not_null
- discounted_price: not_null
- net_price: not_null

---

## Gold Models

### gold_revenue_by_segment
- Depends on: silver_orders, silver_lineitem
- Materialization: table
- Grain: one row per market segment
- Purpose: total revenue and order metrics by customer market segment

| Column              | Type    | Logic                          |
|---------------------|---------|--------------------------------|
| market_segment      | varchar | from silver_orders             |
| total_orders        | integer | COUNT(DISTINCT order_id)       |
| total_revenue       | numeric | SUM(net_price)                 |
| avg_order_value     | numeric | total_revenue / total_orders   |
| total_items_sold    | integer | COUNT(line_number)             |
| return_rate         | numeric | SUM(is_returned) / COUNT(*)    |

Tests:
- market_segment: unique, not_null
- total_revenue: not_null

---

### gold_revenue_by_supplier_nation
- Depends on: silver_lineitem
- Materialization: table
- Grain: one row per supplier nation
- Purpose: revenue and volume metrics by supplier nation

| Column              | Type    | Logic                          |
|---------------------|---------|--------------------------------|
| supplier_nation     | varchar | from silver_lineitem           |
| total_revenue       | numeric | SUM(net_price)                 |
| total_quantity      | numeric | SUM(quantity)                  |
| total_line_items    | integer | COUNT(*)                       |
| avg_discount        | numeric | AVG(discount)                  |
| late_shipment_rate  | numeric | SUM(is_late_shipment) / COUNT(*)|

Tests:
- supplier_nation: unique, not_null
- total_revenue: not_null

---

### gold_revenue_by_part_type
- Depends on: silver_lineitem
- Materialization: table
- Grain: one row per part type
- Purpose: revenue and volume metrics by part type

| Column              | Type    | Logic                          |
|---------------------|---------|--------------------------------|
| part_type           | varchar | from silver_lineitem           |
| total_revenue       | numeric | SUM(net_price)                 |
| total_quantity      | numeric | SUM(quantity)                  |
| total_line_items    | integer | COUNT(*)                       |
| avg_discount        | numeric | AVG(discount)                  |
| return_rate         | numeric | SUM(is_returned) / COUNT(*)    |

Tests:
- part_type: unique, not_null
- total_revenue: not_null

---

## Definition of Done
- [ ] All bronze models build without errors
- [ ] All silver models build without errors
- [ ] All gold models build without errors
- [ ] All tests pass (zero failures)
- [ ] All columns documented in schema.yml
- [ ] PR created with full summary
"@ | Set-Content "C:\Users\Stan\Documents\VScode\mammoth-test\plans\tpch-tech-spec.md"