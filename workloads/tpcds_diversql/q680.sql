WITH joined_data AS (
  SELECT
    cr.cr_order_number,
    ss.ss_ticket_number,
    ws.ws_order_number,
    i.i_category,
    i.i_item_id,
    c.c_customer_id,
    p.p_promo_name,
    sm.sm_carrier,
    w.w_warehouse_name,
    cr.cr_return_amount,
    ss.ss_net_profit AS store_net_profit,
    ws.ws_net_profit AS web_net_profit,
    CASE WHEN cr.cr_return_amount > 0 THEN 1 ELSE 0 END AS has_return
  FROM catalog_returns cr
  JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
  JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
  JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
   AND ss.ss_customer_sk = c.c_customer_sk
  JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_bill_customer_sk = c.c_customer_sk
   AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
   AND ws.ws_promo_sk = p.p_promo_sk
  WHERE sm.sm_carrier IN ('GERMA', 'MSC')
    AND sm.sm_code = 'AIR'
    AND c.c_birth_day BETWEEN 1 AND 15
    AND c.c_last_review_date > 2452400
    AND w.w_county LIKE '%County'
    AND i.i_current_price > 10
    AND p.p_discount_active = 'Y'
),
category_agg AS (
  SELECT
    i_category,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(store_net_profit) AS total_store_profit,
    SUM(web_net_profit) AS total_web_profit,
    COUNT(DISTINCT cr_order_number) AS distinct_returns,
    CASE WHEN SUM(store_net_profit) + SUM(web_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_level
  FROM joined_data
  GROUP BY i_category
),
store_only_orders AS (
  SELECT ss.ss_ticket_number AS order_number
  FROM store_sales ss
  WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2455000
  EXCEPT
  SELECT ws.ws_order_number
  FROM web_sales ws
  WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2455000
)
SELECT
  ca.i_category,
  ca.profit_level,
  ca.total_return_amount,
  ca.total_store_profit,
  ca.total_web_profit,
  ca.distinct_returns,
  LAG(ca.total_store_profit) OVER (ORDER BY ca.total_store_profit DESC) AS prev_store_profit,
  SUM(ca.total_store_profit) OVER (ORDER BY ca.total_store_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_store_profit,
  (SELECT SUM(ss.ss_net_paid_inc_tax) FROM store_sales ss) AS overall_store_paid,
  (SELECT COUNT(*) FROM store_only_orders) AS store_only_order_count
FROM category_agg ca
WHERE ca.total_return_amount > 0
  AND ca.total_store_profit IS NOT NULL
  AND ca.profit_level = 'HIGH'
ORDER BY ca.total_store_profit DESC
LIMIT 100
