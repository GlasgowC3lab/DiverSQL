WITH base AS (
   SELECT
       cs.cs_sold_date_sk,
       cs.cs_sold_time_sk,
       cs.cs_ship_date_sk,
       cs.cs_item_sk,
       cs.cs_promo_sk,
       cs.cs_order_number,
       cs.cs_quantity,
       cs.cs_net_paid,
       cs.cs_ext_discount_amt,
       cs.cs_ext_tax,
       cs.cs_net_profit,
       d.d_year,
       d.d_month_seq,
       t.t_hour,
       i.i_brand,
       i.i_category,
       i.i_product_name,
       p.p_discount_active,
       sm.sm_type,
       hd.hd_buy_potential,
       sr.sr_return_quantity,
       ws.ws_net_paid AS ws_net_paid,
       ws.ws_ext_discount_amt AS ws_ext_discount_amt,
       wp.wp_url,
       inv.inv_quantity_on_hand
   FROM catalog_sales cs
   FULL OUTER JOIN ship_mode sm
       ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   INNER JOIN date_dim d
       ON cs.cs_sold_date_sk = d.d_date_sk
   INNER JOIN time_dim t
       ON cs.cs_sold_time_sk = t.t_time_sk
   INNER JOIN household_demographics hd
       ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   INNER JOIN item i
       ON cs.cs_item_sk = i.i_item_sk
   INNER JOIN promotion p
       ON cs.cs_promo_sk = p.p_promo_sk
   INNER JOIN store_returns sr
       ON sr.sr_item_sk = i.i_item_sk
      AND sr.sr_returned_date_sk = d.d_date_sk
   INNER JOIN web_sales ws
       ON ws.ws_item_sk = i.i_item_sk
      AND ws.ws_sold_date_sk = d.d_date_sk
   INNER JOIN web_page wp
       ON ws.ws_web_page_sk = wp.wp_web_page_sk
   INNER JOIN web_returns wr
       ON wr.wr_item_sk = i.i_item_sk
      AND wr.wr_returned_date_sk = d.d_date_sk
      AND wr.wr_order_number = ws.ws_order_number
      AND wr.wr_web_page_sk = wp.wp_web_page_sk
   INNER JOIN inventory inv
       ON inv.inv_item_sk = i.i_item_sk
      AND inv.inv_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND i.i_brand = 'Brand#12'
     AND p.p_discount_active = 'Y'
     AND sm.sm_type = 'OVERNIGHT'
     AND t.t_hour BETWEEN 9 AND 17
),
agg1 AS (
   SELECT
       d_year,
       i_brand,
       sm_type,
       hd_buy_potential,
       SUM(cs_net_paid) AS total_sales,
       COUNT(DISTINCT cs_order_number) AS distinct_orders,
       MIN(cs_ext_discount_amt) AS min_discount,
       MAX(cs_ext_tax) AS max_tax
   FROM base
   GROUP BY d_year, i_brand, sm_type, hd_buy_potential
),
agg2 AS (
   SELECT
       d_year,
       i_brand,
       sm_type,
       hd_buy_potential,
       AVG(ws_net_paid) AS avg_web_sales,
       SUM(ws_ext_discount_amt) AS total_web_discount,
       MIN(ws_ext_discount_amt) AS min_web_discount,
       MAX(ws_ext_discount_amt) AS max_web_discount
   FROM base
   GROUP BY d_year, i_brand, sm_type, hd_buy_potential
),
union_agg AS (
   SELECT
       d_year,
       i_brand,
       sm_type,
       hd_buy_potential,
       total_sales,
       distinct_orders,
       min_discount,
       max_tax,
       NULL AS avg_web_sales,
       NULL AS total_web_discount,
       NULL AS min_web_discount,
       NULL AS max_web_discount
   FROM agg1
   UNION
   SELECT
       d_year,
       i_brand,
       sm_type,
       hd_buy_potential,
       NULL,
       NULL,
       NULL,
       NULL,
       avg_web_sales,
       total_web_discount,
       min_web_discount,
       max_web_discount
   FROM agg2
),
key_set1 AS (
   SELECT d_year, i_brand FROM agg1
),
key_set2 AS (
   SELECT d_year, i_brand FROM agg2
),
intersect_keys AS (
   SELECT d_year, i_brand FROM key_set1
   INTERSECT
   SELECT d_year, i_brand FROM key_set2
)
SELECT
   u.d_year,
   u.i_brand,
   u.sm_type,
   u.hd_buy_potential,
   SUM(COALESCE(u.total_sales, 0)) AS sum_total_sales,
   SUM(COALESCE(u.distinct_orders, 0)) AS sum_distinct_orders,
   SUM(COALESCE(u.min_discount, 0)) AS sum_min_discount,
   SUM(COALESCE(u.max_tax, 0)) AS sum_max_tax,
   SUM(COALESCE(u.avg_web_sales, 0)) AS sum_avg_web_sales,
   SUM(COALESCE(u.total_web_discount, 0)) AS sum_total_web_discount,
   SUM(COALESCE(u.min_web_discount, 0)) AS sum_min_web_discount,
   SUM(COALESCE(u.max_web_discount, 0)) AS sum_max_web_discount
FROM union_agg u
JOIN intersect_keys ik
  ON u.d_year = ik.d_year AND u.i_brand = ik.i_brand
GROUP BY u.d_year, u.i_brand, u.sm_type, u.hd_buy_potential
ORDER BY sum_total_sales DESC
LIMIT 100
