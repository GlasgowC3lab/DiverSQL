WITH intersect_orders AS (
   SELECT order_num
   FROM (
       SELECT ws_order_number AS order_num
       FROM web_sales
       WHERE ws_ext_sales_price > 5000
         AND ws_sold_date_sk BETWEEN 2450815 AND 2451088
   )
   INTERSECT
   SELECT wr_order_number
   FROM web_returns
   WHERE wr_return_amt > 1000
   EXCEPT
   SELECT sr_ticket_number
   FROM store_returns
   WHERE sr_return_amt > 2000
),
base AS (
   SELECT
       w.w_warehouse_name AS warehouse_name,
       i.i_brand AS brand,
       SUM(ws.ws_net_profit) AS total_profit,
       COUNT(*) AS sales_cnt,
       AVG(ws.ws_ext_discount_amt) AS avg_discount
   FROM store_returns sr
   JOIN time_dim td1 ON sr.sr_return_time_sk = td1.t_time_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk
                         AND wr.wr_order_number = ws.ws_order_number
   JOIN (
       SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)
   ) inv ON inv.inv_item_sk = i.i_item_sk
            AND inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE
       i.i_current_price > 1000
       AND cd.cd_gender = 'F'
       AND r.r_reason_desc IN ('Damaged', 'Defective')
       AND p.p_discount_active = 'Y'
       AND w.w_state = 'CA'
       AND td1.t_hour BETWEEN 8 AND 17
       AND ws.ws_order_number IN (SELECT order_num FROM intersect_orders)
       AND EXISTS (
           SELECT 1
           FROM promotion p2
           WHERE p2.p_promo_sk = ws.ws_promo_sk
             AND p2.p_purpose = 'Clearance'
       )
   GROUP BY w.w_warehouse_name, i.i_brand
)
SELECT
    warehouse_name,
    brand,
    total_profit,
    sales_cnt,
    avg_discount
FROM base
WHERE total_profit > 10000
ORDER BY total_profit DESC
LIMIT 100
