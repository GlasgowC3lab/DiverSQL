WITH sales_union AS (
  SELECT
    ss.ss_ticket_number,
    ss.ss_sold_date_sk,
    ss.ss_sold_time_sk,
    ss.ss_item_sk,
    ss.ss_customer_sk,
    ss.ss_cdemo_sk,
    ss.ss_addr_sk,
    ss.ss_store_sk,
    ss.ss_promo_sk,
    ss.ss_quantity,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    NULL AS ws_web_page_sk,
    NULL AS ws_ship_mode_sk,
    NULL AS ws_warehouse_sk,
    NULL AS ws_web_site_sk
  FROM store_sales ss
  UNION DISTINCT
  SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_sold_time_sk,
    ws.ws_item_sk,
    ws.ws_bill_customer_sk,
    ws.ws_bill_cdemo_sk,
    ws.ws_bill_addr_sk,
    NULL,
    ws.ws_promo_sk,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    ws.ws_web_page_sk,
    ws.ws_ship_mode_sk,
    ws.ws_warehouse_sk,
    ws.ws_web_site_sk
  FROM web_sales ws
)
SELECT
  yr.yr,
  i_sales.i_item_id,
  i_sales.i_category,
  SUM(su.ss_ext_sales_price) AS total_sales,
  SUM(su.ss_net_profit) AS total_profit,
  COUNT(DISTINCT su.ss_ticket_number) AS order_count
FROM sales_union su
JOIN time_dim td
  ON su.ss_sold_time_sk = td.t_time_sk
JOIN item i_sales
  ON su.ss_item_sk = i_sales.i_item_sk
JOIN customer c
  ON su.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON su.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
  ON su.ss_cdemo_sk = cd.cd_demo_sk
JOIN promotion p
  ON su.ss_promo_sk = p.p_promo_sk
JOIN item i_promo
  ON p.p_item_sk = i_promo.i_item_sk
JOIN inventory inv
  ON i_sales.i_item_sk = inv.inv_item_sk
JOIN warehouse w
  ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN ship_mode sm
  ON su.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_page wp
  ON su.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site wsit
  ON su.ws_web_site_sk = wsit.web_site_sk
LEFT JOIN store_returns sr
  ON sr.sr_ticket_number = su.ss_ticket_number
LEFT JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN web_returns wr
  ON wr.wr_order_number = su.ss_ticket_number
CROSS JOIN (VALUES 1) AS dummy_tbl(dummy)
CROSS JOIN (SELECT 2020 AS yr UNION ALL SELECT 2021 AS yr) AS yr
WHERE c.c_current_addr_sk IN (
    SELECT ca2.ca_address_sk
    FROM customer_address ca2
    WHERE ca2.ca_country = 'United States'
)
GROUP BY yr.yr, i_sales.i_item_id, i_sales.i_category
ORDER BY total_sales DESC
LIMIT 100
