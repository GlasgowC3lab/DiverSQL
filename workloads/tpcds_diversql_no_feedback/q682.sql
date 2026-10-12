WITH sales_base AS (
   SELECT
       ca.ca_state,
       ib.ib_income_band_sk,
       ss.ss_net_paid AS store_paid,
       wsale.ws_net_paid AS web_paid,
       cr.cr_return_amount,
       CASE WHEN ss.ss_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS purchase_type,
       i.i_item_desc,
       split(i.i_item_desc, ' ') AS desc_words,
       ib.ib_lower_bound,
       ib.ib_upper_bound
   FROM store_sales ss
   JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN web_sales wsale ON wsale.ws_sold_time_sk = td.t_time_sk
       AND wsale.ws_item_sk = ss.ss_item_sk
   LEFT JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
       AND cr.cr_item_sk = ss.ss_item_sk
   LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN web_site wsite ON wsale.ws_web_site_sk = wsite.web_site_sk
   WHERE td.t_hour BETWEEN 8 AND 19
     AND ca.ca_country = 'United States'
     AND ib.ib_upper_bound >= 50000
     AND i.i_current_price BETWEEN 15 AND 200
     AND cc.cc_state = ca.ca_state
     AND r.r_reason_id IS NOT NULL
),
agg_sales AS (
   SELECT
       ca_state,
       ib_income_band_sk,
       SUM(store_paid) AS total_store_paid,
       SUM(web_paid) AS total_web_paid,
       AVG(cr_return_amount) AS avg_return_amount,
       COUNT(*) AS txn_count,
       ARRAY_AGG(desc_words) AS all_words_arrays
   FROM sales_base
   GROUP BY ca_state, ib_income_band_sk
   HAVING SUM(store_paid) > 10000
)
SELECT
   ca_state,
   ib_income_band_sk,
   total_store_paid,
   total_web_paid,
   avg_return_amount,
   txn_count,
   word
FROM agg_sales
CROSS JOIN UNNEST(all_words_arrays) AS t(words)
CROSS JOIN UNNEST(words) AS u(word)
WHERE word <> ''
ORDER BY total_store_paid DESC
LIMIT 100
