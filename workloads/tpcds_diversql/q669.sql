WITH
  store_sales_agg AS (
    SELECT
      d.d_date AS sales_date,
      d.d_year,
      s.s_state,
      i.i_category,
      SUM(ss.ss_net_profit) AS store_net_profit,
      SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND s.s_state = 'CA'
      AND i.i_category = 'Electronics'
    GROUP BY d.d_date, d.d_year, s.s_state, i.i_category
  ),
  web_sales_agg AS (
    SELECT
      d.d_date AS sales_date,
      d.d_year,
      sm.sm_type,
      SUM(ws.ws_net_profit) AS web_net_profit,
      SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND sm.sm_type = 'AIR'
      AND wsite.web_country = 'United States'
    GROUP BY d.d_date, d.d_year, sm.sm_type
  ),
  catalog_returns_agg AS (
    SELECT
      d.d_date AS return_date,
      SUM(cr.cr_return_amount) AS catalog_return_amount,
      SUM(cr.cr_fee) AS catalog_fee_total
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2000
      AND cc.cc_state = 'CA'
      AND r.r_reason_desc LIKE '%price%'
    GROUP BY d.d_date
  ),
  store_returns_agg AS (
    SELECT
      d.d_date AS return_date,
      SUM(sr.sr_net_loss) AS store_return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2000
      AND s.s_state = 'CA'
      AND r.r_reason_desc LIKE '%price%'
    GROUP BY d.d_date
  )
SELECT
  COALESCE(sa.sales_date, wa.sales_date) AS sales_date,
  SUM(COALESCE(sa.store_net_profit, 0)) AS total_store_net_profit,
  SUM(COALESCE(wa.web_net_profit, 0)) AS total_web_net_profit,
  SUM(COALESCE(cr.catalog_return_amount, 0)) AS total_catalog_return_amount,
  SUM(COALESCE(sr.store_return_loss, 0)) AS total_store_return_loss,
  CASE
    WHEN SUM(COALESCE(sa.store_net_profit, 0) + COALESCE(wa.web_net_profit, 0)) > 0 THEN 'Positive'
    ELSE 'Negative'
  END AS profit_flag,
  (SELECT AVG(store_net_profit) FROM store_sales_agg) AS avg_store_net_profit
FROM store_sales_agg sa
FULL OUTER JOIN web_sales_agg wa
  ON sa.sales_date = wa.sales_date
LEFT JOIN catalog_returns_agg cr
  ON cr.return_date = COALESCE(sa.sales_date, wa.sales_date)
LEFT JOIN store_returns_agg sr
  ON sr.return_date = COALESCE(sa.sales_date, wa.sales_date)
GROUP BY COALESCE(sa.sales_date, wa.sales_date)
HAVING SUM(COALESCE(sa.store_net_profit, 0) + COALESCE(wa.web_net_profit, 0)) > 1500
ORDER BY sales_date
LIMIT 100
