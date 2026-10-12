WITH
  cs AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_time_sk,
      cs.cs_item_sk,
      cs.cs_bill_customer_sk,
      cs.cs_ship_customer_sk,
      cs.cs_warehouse_sk,
      cs.cs_promo_sk,
      cs.cs_call_center_sk,
      cs.cs_catalog_page_sk,
      cs.cs_ext_sales_price,
      cs.cs_net_profit,
      cs.cs_quantity,
      cs.cs_ext_discount_amt,
      cs.cs_sold_date_sk
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450391 AND 2452510                -- predicate 1 (date surrogate range)
      AND cs.cs_quantity > 1                                          -- predicate 2
      AND cs.cs_ext_discount_amt < 100.00                             -- predicate 3
      AND cs.cs_net_profit > 0.00                                     -- predicate 4
  ),
  ws AS (
    SELECT
      ws.ws_order_number,
      ws.ws_item_sk,
      ws.ws_bill_customer_sk,
      ws.ws_sold_time_sk,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      ws.ws_quantity,
      ws.ws_sold_date_sk
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450391 AND 2452510
      AND ws.ws_quantity > 1
      AND ws.ws_net_profit > 0.00
  ),
  intersect_orders AS (
    SELECT cs_order_number FROM cs
    INTERSECT
    SELECT ws_order_number FROM ws
  )
SELECT
  cs.cs_order_number,
  cs.cs_ext_sales_price AS catalog_sales_price,
  ws.ws_ext_sales_price AS web_sales_price,
  wr.wr_return_amt,
  cc.cc_name AS call_center_name,
  cp.cp_type AS catalog_page_type,
  i.i_brand AS item_brand,
  p.p_promo_name AS promo_name,
  t.t_hour AS sale_hour,
  w.w_warehouse_name AS warehouse_name,
  c.c_first_name || ' ' || c.c_last_name AS customer_name,
  RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY cs.cs_net_profit DESC) AS profit_rank,
  COUNT(DISTINCT cs.cs_order_number) OVER () AS distinct_catalog_orders,
  COUNT(DISTINCT ws.ws_order_number) OVER () AS distinct_web_orders
FROM cs
JOIN intersect_orders io ON cs.cs_order_number = io.cs_order_number
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN ws ON cs.cs_order_number = ws.ws_order_number
LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
WHERE cs.cs_ext_sales_price > (
        SELECT AVG(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
      )
LIMIT 100
