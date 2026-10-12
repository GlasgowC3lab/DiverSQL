WITH
joined_data AS (
  SELECT
    cr.cr_order_number,
    cs.cs_quantity,
    cr.cr_return_amount,
    cr.cr_net_loss,
    w.w_warehouse_name,
    ws.ws_quantity AS ws_quantity,
    ws.ws_net_profit,
    wp.wp_web_page_id,
    ws.ws_web_site_sk,
    ws.ws_sold_date_sk,
    cs.cs_ship_mode_sk,
    CASE
      WHEN cr.cr_return_amount > 1000 THEN 'HIGH'
      WHEN cr.cr_return_amount > 100 THEN 'MEDIUM'
      ELSE 'LOW'
    END AS return_level
  FROM catalog_returns cr
  JOIN catalog_sales cs
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
   AND cr.cr_warehouse_sk = cs.cs_warehouse_sk
  JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN web_sales ws
    ON cs.cs_order_number = ws.ws_order_number
   AND cs.cs_item_sk = ws.ws_item_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site site
    ON ws.ws_web_site_sk = site.web_site_sk
  JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
   AND ws.ws_web_page_sk = wr.wr_web_page_sk
  WHERE
    cr.cr_return_ship_cost > 100
    AND cr.cr_refunded_cash > 200
    AND cs.cs_ship_mode_sk IN (5, 8, 10, 11)
    AND w.w_state = 'CA'
    AND wp.wp_type = 'home page'
    AND site.web_country = 'United States'
),

high_loss_orders AS (
  SELECT cr_order_number
  FROM catalog_returns
  WHERE cr_net_loss > (SELECT avg(cr_net_loss) FROM catalog_returns WHERE cr_warehouse_sk = 6)
),

high_profit_orders AS (
  SELECT ws_order_number AS cr_order_number
  FROM web_sales
  WHERE ws_net_profit > (SELECT avg(ws_net_profit) FROM web_sales WHERE ws_warehouse_sk = 6)
),

intersect_orders AS (
  SELECT cr_order_number FROM high_loss_orders
  INTERSECT
  SELECT cr_order_number FROM high_profit_orders
)

SELECT
  jd.w_warehouse_name,
  jd.wp_web_page_id,
  jd.return_level,
  SUM(jd.cs_quantity) AS total_catalog_quantity,
  SUM(jd.ws_quantity) AS total_web_quantity,
  SUM(jd.ws_net_profit) AS total_web_profit,
  COUNT(*) AS txn_count,
  RANK() OVER (PARTITION BY jd.w_warehouse_name ORDER BY SUM(jd.ws_net_profit) DESC) AS profit_rank
FROM joined_data jd
WHERE jd.cr_order_number IN (SELECT cr_order_number FROM intersect_orders)
GROUP BY CUBE (jd.w_warehouse_name, jd.wp_web_page_id, jd.return_level)
HAVING SUM(jd.ws_net_profit) > 0
ORDER BY profit_rank, jd.w_warehouse_name
LIMIT 100
