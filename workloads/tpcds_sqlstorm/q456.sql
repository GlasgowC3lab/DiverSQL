WITH s_sales AS (
 SELECT
   d.d_year,
   d.d_month_seq,
   i.i_category,
   i.i_class,
   i.i_brand,
   'store' AS channel,
   SUM(ss.ss_net_paid) AS net_paid,
   SUM(ss.ss_net_profit) AS net_profit,
   SUM(ss.ss_quantity) AS quantity,
   AVG(ss.ss_ext_discount_amt) AS avg_discount,
   COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
   COUNT(DISTINCT p.p_promo_sk) AS promo_count,
   COUNT(DISTINCT cd.cd_gender) AS gender_variants
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
 LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
 LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
 LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
 WHERE d.d_year BETWEEN 2000 AND 2002
 GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class, i.i_brand
), c_sales AS (
 SELECT
   d.d_year,
   d.d_month_seq,
   i.i_category,
   i.i_class,
   i.i_brand,
   'catalog' AS channel,
   SUM(cs.cs_net_paid) AS net_paid,
   SUM(cs.cs_net_profit) AS net_profit,
   SUM(cs.cs_quantity) AS quantity,
   AVG(cs.cs_ext_discount_amt) AS avg_discount,
   COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
   COUNT(DISTINCT p.p_promo_sk) AS promo_count,
   COUNT(DISTINCT cd.cd_gender) AS gender_variants
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
 LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
 LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
 LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
 WHERE d.d_year BETWEEN 2000 AND 2002
 GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class, i.i_brand
), w_sales AS (
 SELECT
   d.d_year,
   d.d_month_seq,
   i.i_category,
   i.i_class,
   i.i_brand,
   'web' AS channel,
   SUM(ws.ws_net_paid) AS net_paid,
   SUM(ws.ws_net_profit) AS net_profit,
   SUM(ws.ws_quantity) AS quantity,
   AVG(ws.ws_ext_discount_amt) AS avg_discount,
   COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
   COUNT(DISTINCT p.p_promo_sk) AS promo_count,
   COUNT(DISTINCT cd.cd_gender) AS gender_variants
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
 LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
 LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
 LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
 WHERE d.d_year BETWEEN 2000 AND 2002
 GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class, i.i_brand
), combined AS (
 SELECT * FROM s_sales
 UNION ALL
 SELECT * FROM c_sales
 UNION ALL
 SELECT * FROM w_sales
), ranked AS (
 SELECT
   d_year,
   d_month_seq,
   i_category,
   i_class,
   i_brand,
   channel,
   net_paid,
   net_profit,
   quantity,
   avg_discount,
   distinct_customers,
   promo_count,
   gender_variants,
   RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY net_profit DESC) AS profit_rank
 FROM combined
)
SELECT
 d_year,
 d_month_seq,
 i_category,
 i_class,
 i_brand,
 channel,
 net_paid,
 net_profit,
 quantity,
 avg_discount,
 distinct_customers,
 promo_count,
 gender_variants,
 profit_rank
FROM ranked
WHERE profit_rank <= 5
ORDER BY d_year, d_month_seq, profit_rank
