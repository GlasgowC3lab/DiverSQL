SELECT
  p_cs.p_promo_name,
  cp.cp_department,
  d_sales.d_year,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  SUM(cr.cr_return_amount) AS total_returns,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
  COUNT(DISTINCT cr.cr_returned_date_sk) AS distinct_return_days
FROM catalog_sales cs
JOIN date_dim d_sales
  ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w_cs
  ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
JOIN promotion p_cs
  ON cs.cs_promo_sk = p_cs.p_promo_sk
JOIN catalog_returns cr
  ON cr.cr_item_sk = cs.cs_item_sk
  AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_ret
  ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN warehouse w_cr
  ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN catalog_page cp_ret
  ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN promotion p_ss
  ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d_sales.d_date_sk
JOIN date_dim d_ws_close
  ON ws.web_close_date_sk = d_ws_close.d_date_sk
GROUP BY ROLLUP (p_cs.p_promo_name, cp.cp_department, d_sales.d_year)
ORDER BY total_sales DESC
LIMIT 100
