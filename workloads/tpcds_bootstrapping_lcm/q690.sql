SELECT
  cp.cp_department,
  s.s_state,
  w.web_country,
  d_start.d_year AS start_year,
  d_start.d_month_seq AS start_month,
  COUNT(DISTINCT cp.cp_catalog_page_id) AS catalog_pages,
  COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
  SUM(i.inv_quantity_on_hand) AS total_quantity,
  AVG(i.inv_quantity_on_hand) AS avg_quantity,
  MIN(d_inv.d_date) AS earliest_inventory_date,
  MAX(d_inv.d_date) AS latest_inventory_date
FROM catalog_page cp
JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
CROSS JOIN inventory i
JOIN date_dim d_inv ON i.inv_date_sk = d_inv.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
CROSS JOIN web_site w
JOIN date_dim d_web_open ON w.web_open_date_sk = d_web_open.d_date_sk
JOIN date_dim d_web_close ON w.web_close_date_sk = d_web_close.d_date_sk
WHERE d_inv.d_date BETWEEN d_start.d_date AND d_end.d_date
  AND d_inv.d_date BETWEEN d_web_open.d_date AND d_web_close.d_date
  AND (d_store.d_date IS NULL OR d_inv.d_date <= d_store.d_date)
GROUP BY cp.cp_department, s.s_state, w.web_country, d_start.d_year, d_start.d_month_seq
HAVING SUM(i.inv_quantity_on_hand) > 0
ORDER BY total_quantity DESC
LIMIT 100
