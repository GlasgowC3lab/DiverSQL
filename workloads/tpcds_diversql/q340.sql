WITH cs_agg AS (
   SELECT
      d.d_year,
      i.i_category,
      SUM(cs.cs_ext_sales_price)               AS cs_sales,
      SUM(cs.cs_net_profit)                    AS cs_profit,
      COUNT(*)                                 AS cs_cnt
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN inventory inv
          ON inv.inv_date_sk = d.d_date_sk
         AND inv.inv_item_sk = i.i_item_sk
         AND inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_year = 2001
     AND i.i_brand = 'Brand#12'
     AND sm.sm_code = 'AIR'
   GROUP BY d.d_year, i.i_category
),
ws_agg AS (
   SELECT
      d.d_year,
      i.i_category,
      SUM(ws.ws_ext_sales_price)                                    AS ws_sales,
      SUM(ws.ws_net_profit)                                         AS ws_profit,
      COUNT(*)                                                      AS ws_cnt,
      SUM(CASE WHEN ws.ws_net_paid_inc_tax > 5000 THEN ws.ws_net_paid_inc_tax ELSE 0 END) AS high_net_paid
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
   LEFT JOIN web_returns wr
          ON wr.wr_order_number = ws.ws_order_number
         AND wr.wr_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
     AND we.web_country = 'United States'
     AND sm.sm_contract = 'Ek'
   GROUP BY d.d_year, i.i_category
),
ss_agg AS (
   SELECT
      d.d_year,
      i.i_category,
      SUM(ss.ss_ext_sales_price) AS ss_sales,
      SUM(ss.ss_net_profit)      AS ss_profit,
      COUNT(*)                  AS ss_cnt
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE d.d_year = 2001
     AND i.i_size = 'MEDIUM'
     AND ca.ca_country = 'United States'
   GROUP BY d.d_year, i.i_category
)
SELECT
   COALESCE(cs.d_year, ws.d_year, ss.d_year)                                 AS year,
   COALESCE(cs.i_category, ws.i_category, ss.i_category)                     AS category,
   COALESCE(cs.cs_sales, 0)                                                  AS catalog_sales,
   COALESCE(ws.ws_sales, 0)                                                  AS web_sales,
   COALESCE(ss.ss_sales, 0)                                                  AS store_sales,
   (COALESCE(cs.cs_sales, 0) + COALESCE(ws.ws_sales, 0) + COALESCE(ss.ss_sales, 0)) AS total_sales,
   CASE
      WHEN (COALESCE(cs.cs_sales, 0) + COALESCE(ws.ws_sales, 0) + COALESCE(ss.ss_sales, 0)) > 1000000 THEN 'Very High'
      WHEN (COALESCE(cs.cs_sales, 0) + COALESCE(ws.ws_sales, 0) + COALESCE(ss.ss_sales, 0)) > 500000  THEN 'High'
      ELSE 'Normal'
   END                                                                       AS sales_level
FROM cs_agg cs
FULL OUTER JOIN ws_agg ws
   ON cs.d_year = ws.d_year AND cs.i_category = ws.i_category
LEFT JOIN ss_agg ss
   ON COALESCE(cs.d_year, ws.d_year) = ss.d_year
  AND COALESCE(cs.i_category, ws.i_category) = ss.i_category
WHERE (COALESCE(cs.cs_sales, 0) + COALESCE(ws.ws_sales, 0) + COALESCE(ss.ss_sales, 0)) > 200000
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
