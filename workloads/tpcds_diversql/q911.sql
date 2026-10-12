WITH base_sales AS (
   SELECT
       s.s_store_sk,
       s.s_store_name,
       s.s_state,
       i.i_item_sk,
       i.i_category,
       d.d_year,
       hd.hd_vehicle_count,
       hd.hd_income_band_sk,
       ss.ss_ticket_number,
       ss.ss_ext_sales_price        AS ss_sales,
       cs.cs_ext_sales_price        AS cs_sales,
       ws.ws_ext_sales_price        AS ws_sales,
       ws.ws_net_profit             AS ws_profit,
       inv.inv_quantity_on_hand
   FROM store_sales ss
   JOIN date_dim d                     ON ss.ss_sold_date_sk   = d.d_date_sk
   JOIN store s                        ON ss.ss_store_sk      = s.s_store_sk
   JOIN item i                         ON ss.ss_item_sk       = i.i_item_sk
   JOIN household_demographics hd      ON ss.ss_hdemo_sk      = hd.hd_demo_sk
   JOIN customer_address ca           ON ss.ss_addr_sk       = ca.ca_address_sk
   JOIN promotion p_ss                 ON ss.ss_promo_sk      = p_ss.p_promo_sk
   JOIN inventory inv                  ON inv.inv_item_sk     = i.i_item_sk
                                         AND inv.inv_date_sk   = d.d_date_sk
   JOIN catalog_sales cs               ON cs.cs_sold_date_sk = d.d_date_sk
                                         AND cs.cs_item_sk     = i.i_item_sk
   JOIN ship_mode sm                   ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN call_center cc                 ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN promotion p_cs                 ON cs.cs_promo_sk      = p_cs.p_promo_sk
   JOIN web_sales ws                  ON ws.ws_sold_date_sk = d.d_date_sk
                                         AND ws.ws_item_sk     = i.i_item_sk
   JOIN web_page wp                    ON ws.ws_web_page_sk  = wp.wp_web_page_sk
   JOIN web_site wsite                  ON ws.ws_web_site_sk  = wsite.web_site_sk
   JOIN promotion p_ws                 ON ws.ws_promo_sk     = p_ws.p_promo_sk
   JOIN ship_mode sm_ws                ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
   JOIN income_band ib                ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE d.d_year = 2001
     AND s.s_state = 'CA'
     AND i.i_category = 'Sports'
     AND cc.cc_company_name = 'able'
     AND ib.ib_upper_bound < 50000
     AND inv.inv_quantity_on_hand > 1000
     AND EXISTS (
         SELECT 1 FROM promotion p_check
         WHERE p_check.p_item_sk = i.i_item_sk
           AND p_check.p_discount_active = 'Y'
     )
),
agg_sales AS (
   SELECT
       bs.s_store_name,
       bs.i_category,
       bs.d_year,
       bs.hd_vehicle_count,
       bs.i_item_sk,
       CASE WHEN bs.hd_vehicle_count > 2 THEN 'HighVehicle' ELSE 'LowVehicle' END AS vehicle_segment,
       SUM(bs.ss_sales + bs.cs_sales + bs.ws_sales)                     AS total_sales,
       COUNT(DISTINCT bs.ss_ticket_number)                             AS store_sales_txn_cnt,
       AVG(bs.ws_profit)                                                AS avg_web_profit,
       MIN(d_full.d_date)                                               AS first_sale_date,
       (
           SELECT SUM(inv2.inv_quantity_on_hand)
           FROM inventory inv2
           JOIN date_dim d2 ON inv2.inv_date_sk = d2.d_date_sk
           WHERE inv2.inv_item_sk = bs.i_item_sk
             AND d2.d_year = bs.d_year
       )                                                               AS total_inventory_year
   FROM base_sales bs
   JOIN date_dim d_full ON bs.d_year = d_full.d_year
   GROUP BY
       bs.s_store_name,
       bs.i_category,
       bs.d_year,
       bs.hd_vehicle_count,
       bs.i_item_sk
)
SELECT
    t.s_store_name,
    t.i_category,
    t.d_year,
    t.vehicle_segment,
    t.total_sales,
    t.store_sales_txn_cnt,
    t.avg_web_profit,
    t.first_sale_date,
    t.total_inventory_year
FROM (
    SELECT
        a.*, 
        ROW_NUMBER() OVER (PARTITION BY a.s_store_name ORDER BY a.total_sales DESC) AS rn
    FROM agg_sales a
) t
WHERE t.rn <= 3
ORDER BY t.total_sales DESC
LIMIT 100
