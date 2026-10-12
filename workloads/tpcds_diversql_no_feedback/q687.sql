SELECT
  d_ss_date.d_year AS sale_year,
  i.i_category,
  p.p_promo_name,
  sm_cs.sm_type AS ship_mode,
  r_cr.r_reason_desc AS catalog_return_reason,
  wp.wp_type AS web_page_type,
  SUM(ss.ss_net_paid) AS total_store_sales,
  SUM(cs.cs_net_paid) AS total_catalog_sales,
  SUM(cr.cr_return_amount) AS total_catalog_returns,
  SUM(wr.wr_return_amt) AS total_web_returns
FROM store_sales ss
RIGHT OUTER JOIN time_dim td_time
  ON ss.ss_sold_time_sk = td_time.t_time_sk
JOIN date_dim d_ss_date
  ON ss.ss_sold_date_sk = d_ss_date.d_date_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
  ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
  ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN catalog_sales cs
  ON cs.cs_item_sk = i.i_item_sk
  AND cs.cs_sold_date_sk = d_ss_date.d_date_sk
JOIN date_dim d_cs_date
  ON cs.cs_sold_date_sk = d_cs_date.d_date_sk
JOIN time_dim td_cs_time
  ON cs.cs_sold_time_sk = td_cs_time.t_time_sk
JOIN ship_mode sm_cs
  ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
  AND cr.cr_item_sk = i.i_item_sk
JOIN date_dim d_cr_date
  ON cr.cr_returned_date_sk = d_cr_date.d_date_sk
JOIN time_dim td_cr_time
  ON cr.cr_returned_time_sk = td_cr_time.t_time_sk
JOIN reason r_cr
  ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN ship_mode sm_cr
  ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN catalog_page cp_cr
  ON cr.cr_catalog_page_sk = cp_cr.cp_catalog_page_sk
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
JOIN date_dim d_wr_date
  ON wr.wr_returned_date_sk = d_wr_date.d_date_sk
JOIN time_dim td_wr_time
  ON wr.wr_returned_time_sk = td_wr_time.t_time_sk
JOIN reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_order_number = cs.cs_order_number
)
GROUP BY
  d_ss_date.d_year,
  i.i_category,
  p.p_promo_name,
  sm_cs.sm_type,
  r_cr.r_reason_desc,
  wp.wp_type
ORDER BY total_store_sales DESC
LIMIT 100
