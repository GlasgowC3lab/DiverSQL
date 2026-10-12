WITH
  d_sales AS (
    SELECT * FROM date_dim WHERE d_year = 2002
  ),
  d_return AS (
    SELECT * FROM date_dim WHERE d_year = 2003
  ),
  d_promo_start AS (
    SELECT * FROM date_dim
  )
SELECT
  d_sales.d_year,
  s.s_state,
  CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_category,
  SUM(ss.ss_net_paid) AS total_net_paid,
  SUM(cr.cr_net_loss) AS total_cr_net_loss,
  COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt
FROM store_sales ss
RIGHT OUTER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN d_sales d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
LEFT JOIN time_dim t_s ON ss.ss_sold_time_sk = t_s.t_time_sk
LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
LEFT JOIN d_return d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
LEFT JOIN time_dim t_r ON sr.sr_return_time_sk = t_r.t_time_sk
LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_return.d_date_sk
LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d_return.d_date_sk
LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN d_promo_start d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
WHERE s.s_store_id IN (SELECT s_store_id FROM store WHERE s_number_employees > 200)
GROUP BY
  d_sales.d_year,
  s.s_state,
  CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END
UNION DISTINCT
SELECT
  d_sales.d_year,
  s.s_state,
  CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_category,
  SUM(ss.ss_net_paid) AS total_net_paid,
  SUM(cr.cr_net_loss) AS total_cr_net_loss,
  COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt
FROM store_sales ss
RIGHT OUTER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN d_sales d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
LEFT JOIN time_dim t_s ON ss.ss_sold_time_sk = t_s.t_time_sk
LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
LEFT JOIN d_return d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
LEFT JOIN time_dim t_r ON sr.sr_return_time_sk = t_r.t_time_sk
LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_return.d_date_sk
LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d_return.d_date_sk
LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN d_promo_start d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
WHERE p.p_discount_active = 'N'
  AND s.s_store_id IN (SELECT s_store_id FROM store WHERE s_number_employees > 200)
GROUP BY
  d_sales.d_year,
  s.s_state,
  CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END
ORDER BY total_net_paid DESC
OFFSET 10
LIMIT 100
