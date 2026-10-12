WITH store_part AS (
  SELECT
    'store' AS channel,
    SUM(ss.ss_net_paid_inc_tax) AS sales_amount,
    SUM(sr.sr_net_loss) AS return_loss,
    COUNT(DISTINCT ss.ss_ticket_number) AS txn_cnt
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  RIGHT OUTER JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                     AND sr.sr_item_sk = ss.ss_item_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE d.d_year = 2001
    AND d.d_month_seq BETWEEN 1200 AND 1210
    AND s.s_state = 'CA'
    AND ca.ca_country = 'United States'
    AND cd.cd_gender = 'M'
    AND r.r_reason_desc = 'Damaged'
    AND ss.ss_quantity > 1
),
web_part AS (
  SELECT
    'web' AS channel,
    SUM(ws.ws_net_paid_inc_tax) AS sales_amount,
    SUM(wr.wr_net_loss) AS return_loss,
    COUNT(DISTINCT ws.ws_order_number) AS txn_cnt
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                     AND wr.wr_item_sk = ws.ws_item_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN catalog_returns cr ON cr.cr_reason_sk = r.r_reason_sk
  WHERE d.d_year = 2001
    AND d.d_month_seq BETWEEN 1200 AND 1210
    AND sm.sm_type = 'AIR'
    AND w.w_city = 'Riverside'
    AND we.web_country = 'United States'
    AND wp.wp_type = 'content'
    AND cr.cr_return_amount > 0
)
SELECT
  channel,
  SUM(sales_amount) AS total_sales,
  SUM(return_loss) AS total_return_loss,
  SUM(txn_cnt) AS total_transactions
FROM (
  SELECT * FROM store_part
  UNION DISTINCT
  SELECT * FROM web_part
) AS combined
GROUP BY channel
ORDER BY total_sales DESC
LIMIT 100
