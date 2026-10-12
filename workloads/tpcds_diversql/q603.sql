WITH base AS (
   SELECT cs.*
   FROM catalog_sales cs
   TABLESAMPLE BERNOULLI (10)
   WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451170
     AND cs.cs_sold_date_sk NOT IN (SELECT sr.sr_returned_date_sk FROM store_returns sr)
),
agg AS (
   SELECT
     cs.cs_sold_date_sk,
     t.t_hour,
     i.i_category,
     i.i_brand,
     p.p_promo_name,
     cp.cp_department,
     sm.sm_type,
     w.w_warehouse_name,
     c.c_customer_id,
     SUM(cs.cs_ext_sales_price)      AS total_sales,
     SUM(cs.cs_net_profit)           AS total_profit,
     COUNT(*)                        AS cnt_sales
   FROM base cs
   JOIN time_dim t      ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN item i          ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p     ON cs.cs_promo_sk = p.p_promo_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   RIGHT OUTER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN customer c     ON cs.cs_bill_customer_sk = c.c_customer_sk
   LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN store_sales ss   ON ss.ss_item_sk = i.i_item_sk
   LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
   LEFT JOIN reason r         ON sr.sr_reason_sk = r.r_reason_sk
   LEFT JOIN store s          ON sr.sr_store_sk = s.s_store_sk
   GROUP BY GROUPING SETS (
        (cs.cs_sold_date_sk, i.i_category, t.t_hour),
        (cs.cs_sold_date_sk, i.i_brand),
        (cs.cs_sold_date_sk)
   ),
   cp.cp_department, sm.sm_type, w.w_warehouse_name, c.c_customer_id, p.p_promo_name
)
SELECT
   cs_sold_date_sk,
   i_category,
   i_brand,
   total_sales,
   total_profit,
   cnt_sales,
   ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_profit DESC) AS rnk_category,
   CASE WHEN total_profit > 5000 THEN 'High'
        WHEN total_profit > 0    THEN 'Medium'
        ELSE 'Low' END AS profit_bucket
FROM agg
WHERE i_category IS NOT NULL OR i_brand IS NOT NULL
UNION DISTINCT
SELECT
   cs_sold_date_sk,
   i_category,
   i_brand,
   total_sales,
   total_profit,
   cnt_sales,
   NULL AS rnk_category,
   'Aggregated' AS profit_bucket
FROM agg
WHERE cnt_sales > 10
ORDER BY cs_sold_date_sk DESC
LIMIT 100
