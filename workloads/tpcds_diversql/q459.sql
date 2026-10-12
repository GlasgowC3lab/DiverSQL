WITH ws_base AS (
   SELECT
       ws_order_number,
       ws_sold_date_sk,
       ws_sold_time_sk,
       ws_ship_date_sk,
       ws_item_sk,
       ws_bill_addr_sk,
       ws_ship_addr_sk,
       ws_web_page_sk,
       ws_net_paid_inc_ship,
       ws_quantity,
       ws_ext_sales_price,
       ws_ext_discount_amt,
       ws_net_profit
   FROM web_sales
   WHERE ws_net_paid_inc_ship > 500
     AND ws_quantity BETWEEN 1 AND 20
     AND ws_ext_discount_amt < 2000
),
order_set1 AS (
   SELECT ws_order_number
   FROM ws_base
   WHERE ws_sold_date_sk IN (
       SELECT d_date_sk FROM date_dim WHERE d_year = 2002
   )
),
order_set2 AS (
   SELECT ws_order_number
   FROM ws_base
   WHERE ws_sold_time_sk IN (
       SELECT t_time_sk FROM time_dim WHERE t_hour BETWEEN 9 AND 17
   )
),
common_orders AS (
   SELECT ws_order_number FROM order_set1
   INTERSECT
   SELECT ws_order_number FROM order_set2
)
SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    t.t_hour,
    i.i_category,
    i.i_manager_id,
    ca_bill.ca_state AS bill_state,
    ca_ship.ca_state AS ship_state,
    wp.wp_type,
    ws_base.ws_order_number,
    ws_base.ws_net_paid_inc_ship,
    ws_base.ws_quantity,
    CASE
        WHEN i.i_current_price > 100 THEN 'Expensive'
        WHEN i.i_current_price > 50 THEN 'Mid'
        ELSE 'Cheap'
    END AS price_category,
    (SELECT AVG(i2.i_current_price)
       FROM item i2
       WHERE i2.i_category = i.i_category) AS avg_category_price,
    SUM(ws_base.ws_ext_sales_price) OVER (
        PARTITION BY d_sold.d_year
        ORDER BY ws_base.ws_net_paid_inc_ship DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sales,
    RANK() OVER (PARTITION BY d_sold.d_year ORDER BY ws_base.ws_net_paid_inc_ship DESC) AS sales_rank,
    COUNT(DISTINCT ws_base.ws_bill_addr_sk) OVER (PARTITION BY d_sold.d_year) AS distinct_bill_customers,
    COUNT(DISTINCT ws_base.ws_ship_addr_sk) OVER (PARTITION BY d_sold.d_year) AS distinct_ship_customers
FROM ws_base
JOIN common_orders co
   ON ws_base.ws_order_number = co.ws_order_number
JOIN date_dim d_sold
   ON ws_base.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t
   ON ws_base.ws_sold_time_sk = t.t_time_sk
JOIN date_dim d_ship
   ON ws_base.ws_ship_date_sk = d_ship.d_date_sk
JOIN item i
   ON ws_base.ws_item_sk = i.i_item_sk
JOIN customer_address ca_bill
   ON ws_base.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
   ON ws_base.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_page wp
   ON ws_base.ws_web_page_sk = wp.wp_web_page_sk
WHERE d_sold.d_year = 2002
  AND t.t_hour BETWEEN 9 AND 17
  AND ca_bill.ca_state = 'CA'
  AND wp.wp_type IN ('Content', 'Navigation')
ORDER BY d_sold.d_year, sales_rank
LIMIT 100
