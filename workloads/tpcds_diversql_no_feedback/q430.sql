WITH sales_agg AS (
  SELECT
    s.s_store_id AS store_id,
    i.i_item_id AS item_id,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_returns,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    AVG(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS pct_active_promo,
    MAX(wp.wp_type) AS any_page_type
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
  LEFT JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
  LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE
    s.s_state = 'CA'
    AND i.i_current_price > 50
    AND p.p_channel_email = 'Y'
    AND ca.ca_country = 'United States'
    AND hd.hd_income_band_sk IN (
      SELECT hd2.hd_income_band_sk
      FROM household_demographics hd2
      WHERE hd2.hd_vehicle_count > 1
    )
    AND w.w_state = 'CA'
    AND wp.wp_type = 'article'
  GROUP BY
    s.s_store_id,
    i.i_item_id
)
SELECT
  store_id,
  item_id,
  total_sales,
  total_returns,
  (total_sales - total_returns) AS net_sales,
  total_inventory,
  pct_active_promo,
  CASE WHEN (total_sales - total_returns) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS sales_status
FROM sales_agg
WHERE total_sales > (SELECT AVG(ss_ext_sales_price) FROM store_sales)
ORDER BY net_sales DESC
LIMIT 100
