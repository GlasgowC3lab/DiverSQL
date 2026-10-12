SELECT
  cp.cp_catalog_page_id,
  cp.cp_catalog_page_number,
  cp.cp_department,
  cp.cp_type,
  cp_start.d_date AS catalog_start_date,
  cp_end.d_date AS catalog_end_date,
  date_diff('day', cp_start.d_date, cp_end.d_date) AS catalog_page_duration_days,
  dr.d_date AS return_date,
  dr.d_year,
  dr.d_month_seq,
  dr.d_day_name,
  s.s_store_id,
  s.s_city,
  s.s_state,
  s.s_market_desc,
  CASE WHEN s.s_closed_date_sk IS NOT NULL THEN 'Closed' ELSE 'Open' END AS store_status,
  wp.wp_web_page_id,
  wp.wp_url,
  wp.wp_type,
  wp.wp_image_count,
  wp.wp_link_count,
  wp_access.d_date AS web_page_access_date,
  cr.cr_return_amount,
  cr.cr_return_tax,
  cr.cr_return_quantity,
  cr.cr_net_loss,
  (cr.cr_return_amount - cr.cr_return_tax) AS net_return_excluding_tax,
  CASE
    WHEN cr.cr_return_amount > 200 THEN 'High'
    WHEN cr.cr_return_amount > 100 THEN 'Medium'
    ELSE 'Low'
  END AS return_amount_category,
  date_diff('day', cp_start.d_date, dr.d_date) AS days_from_catalog_start_to_return,
  date_diff('day', dr.d_date, wp_access.d_date) AS days_from_return_to_web_access
FROM catalog_returns cr
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim dr
  ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN date_dim cp_end
  ON cp.cp_end_date_sk = cp_end.d_date_sk
JOIN date_dim cp_start
  ON cp.cp_start_date_sk = cp_start.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = dr.d_date_sk
JOIN web_page wp
  ON wp.wp_creation_date_sk = dr.d_date_sk
JOIN date_dim wp_access
  ON wp.wp_access_date_sk = wp_access.d_date_sk
WHERE cr.cr_return_amount > 0
ORDER BY dr.d_date DESC
LIMIT 100
