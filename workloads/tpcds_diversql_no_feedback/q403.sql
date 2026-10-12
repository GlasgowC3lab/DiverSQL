WITH sales_data AS (
   -- Catalog sales channel
   SELECT
     i.i_item_id,
     CAST(NULL AS varchar) AS store_id,
     cs.cs_ext_sales_price AS sales,
     cs.cs_net_profit AS profit,
     cp.cp_department,
     p.p_promo_name,
     t.t_hour,
     ca.ca_state,
     c.c_first_name,
     c.c_last_name,
     sm.sm_type AS ship_mode_type,
     inv.inv_quantity_on_hand,
     CAST(NULL AS varchar) AS web_page_type,
     CAST(NULL AS varchar) AS web_site_name
   FROM catalog_sales cs
   JOIN catalog_page cp               ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN promotion p                   ON cs.cs_promo_sk = p.p_promo_sk
   JOIN item i                        ON cs.cs_item_sk = i.i_item_sk
   JOIN ship_mode sm                 ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer c                    ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca           ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN time_dim t                    ON cs.cs_sold_time_sk = t.t_time_sk
   LEFT JOIN inventory inv            ON i.i_item_sk = inv.inv_item_sk
   WHERE
     i.i_category = 'Electronics'
     AND cp.cp_department = 'Home'
     AND p.p_discount_active = 'Y'
     AND c.c_birth_year = 1985
     AND i.i_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'

   UNION ALL

   -- Store sales channel (right outer join keeps all stores)
   SELECT
     i.i_item_id,
     s.s_store_id,
     ss.ss_ext_sales_price AS sales,
     ss.ss_net_profit AS profit,
     CAST(NULL AS varchar) AS cp_department,
     p.p_promo_name,
     t.t_hour,
     ca.ca_state,
     c.c_first_name,
     c.c_last_name,
     CAST(NULL AS varchar) AS ship_mode_type,
     inv.inv_quantity_on_hand,
     CAST(NULL AS varchar) AS web_page_type,
     CAST(NULL AS varchar) AS web_site_name
   FROM store_sales ss
   RIGHT OUTER JOIN store s            ON ss.ss_store_sk = s.s_store_sk
   LEFT JOIN promotion p               ON ss.ss_promo_sk = p.p_promo_sk
   LEFT JOIN item i                    ON ss.ss_item_sk = i.i_item_sk
   LEFT JOIN customer c                ON ss.ss_customer_sk = c.c_customer_sk
   LEFT JOIN customer_address ca       ON ss.ss_addr_sk = ca.ca_address_sk
   LEFT JOIN time_dim t                ON ss.ss_sold_time_sk = t.t_time_sk
   LEFT JOIN inventory inv             ON i.i_item_sk = inv.inv_item_sk
   WHERE
     s.s_manager IN ('Matt Frederick', 'David Thomas')
     AND s.s_geography_class = 'Unknown'
     AND s.s_company_id = 1
     AND i.i_rec_end_date > DATE '2001-01-01'

   UNION ALL

   -- Web sales channel
   SELECT
     i.i_item_id,
     CAST(NULL AS varchar) AS store_id,
     ws.ws_ext_sales_price AS sales,
     ws.ws_net_profit AS profit,
     CAST(NULL AS varchar) AS cp_department,
     p.p_promo_name,
     t.t_hour,
     ca.ca_state,
     c.c_first_name,
     c.c_last_name,
     sm.sm_type AS ship_mode_type,
     inv.inv_quantity_on_hand,
     wp.wp_type AS web_page_type,
     web.web_name AS web_site_name
   FROM web_sales ws
   JOIN item i                        ON ws.ws_item_sk = i.i_item_sk
   JOIN promotion p                    ON ws.ws_promo_sk = p.p_promo_sk
   JOIN ship_mode sm                  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer c                    ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca           ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN time_dim t                    ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN web_page wp                   ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site web                  ON ws.ws_web_site_sk = web.web_site_sk
   LEFT JOIN inventory inv            ON i.i_item_sk = inv.inv_item_sk
   WHERE
     wp.wp_type = 'Content'
     AND web.web_name LIKE 'Shop%'
     AND sm.sm_carrier = 'UPS'
     AND p.p_promo_name LIKE '%Holiday%'

   UNION ALL

   -- Store returns channel (treated as negative sales)
   SELECT
     i.i_item_id,
     s.s_store_id,
     -sr.sr_return_amt AS sales,
     -sr.sr_net_loss AS profit,
     CAST(NULL AS varchar) AS cp_department,
     CAST(NULL AS varchar) AS p_promo_name,
     t.t_hour,
     ca.ca_state,
     c.c_first_name,
     c.c_last_name,
     CAST(NULL AS varchar) AS ship_mode_type,
     inv.inv_quantity_on_hand,
     CAST(NULL AS varchar) AS web_page_type,
     CAST(NULL AS varchar) AS web_site_name
   FROM store_returns sr
   JOIN store s                        ON sr.sr_store_sk = s.s_store_sk
   JOIN reason r                       ON sr.sr_reason_sk = r.r_reason_sk
   JOIN item i                         ON sr.sr_item_sk = i.i_item_sk
   JOIN customer c                     ON sr.sr_customer_sk = c.c_customer_sk
   JOIN customer_address ca            ON sr.sr_addr_sk = ca.ca_address_sk
   JOIN time_dim t                     ON sr.sr_return_time_sk = t.t_time_sk
   LEFT JOIN inventory inv             ON i.i_item_sk = inv.inv_item_sk
   WHERE
     r.r_reason_desc = 'Damaged'
     AND s.s_store_name LIKE 'Store%'
     AND ca.ca_state = 'CA'
     AND t.t_hour BETWEEN 9 AND 17
)
SELECT
   i_item_id,
   COALESCE(store_id, 'NO_STORE') AS store_id,
   SUM(sales) AS total_sales,
   SUM(profit) AS total_profit,
   AVG(profit) AS avg_profit_per_transaction
FROM sales_data
GROUP BY i_item_id, store_id
HAVING SUM(sales) > 1000
ORDER BY total_sales DESC, i_item_id
