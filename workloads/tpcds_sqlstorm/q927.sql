WITH cs AS (
 SELECT
   d.d_year,
   d.d_moy AS month,
   i.i_category,
   i.i_brand,
   p.p_promo_id,
   cc.cc_country AS country,
   SUM(cs.cs_ext_sales_price) AS total_sales,
   SUM(cs.cs_ext_discount_amt) AS total_discount,
   SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
   SUM(cs.cs_net_profit) AS total_profit,
   COUNT(*) AS order_count
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
 JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
 WHERE d.d_year BETWEEN 2001 AND 2002
 GROUP BY d.d_year, d.d_moy, i.i_category, i.i_brand, p.p_promo_id, cc.cc_country
),
ss AS (
 SELECT
   d.d_year,
   d.d_moy AS month,
   i.i_category,
   i.i_brand,
   p.p_promo_id,
   s.s_country AS country,
   SUM(ss.ss_ext_sales_price) AS total_sales,
   SUM(ss.ss_ext_discount_amt) AS total_discount,
   0 AS total_ship_cost,
   SUM(ss.ss_net_profit) AS total_profit,
   COUNT(*) AS order_count
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
 JOIN store s ON ss.ss_store_sk = s.s_store_sk
 WHERE d.d_year BETWEEN 2001 AND 2002
 GROUP BY d.d_year, d.d_moy, i.i_category, i.i_brand, p.p_promo_id, s.s_country
),
ws AS (
 SELECT
   d.d_year,
   d.d_moy AS month,
   i.i_category,
   i.i_brand,
   p.p_promo_id,
   w.web_country AS country,
   SUM(ws.ws_ext_sales_price) AS total_sales,
   SUM(ws.ws_ext_discount_amt) AS total_discount,
   SUM(ws.ws_ext_ship_cost) AS total_ship_cost,
   SUM(ws.ws_net_profit) AS total_profit,
   COUNT(*) AS order_count
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
 JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
 WHERE d.d_year BETWEEN 2001 AND 2002
 GROUP BY d.d_year, d.d_moy, i.i_category, i.i_brand, p.p_promo_id, w.web_country
),
combined AS (
 SELECT * FROM cs
 UNION ALL
 SELECT * FROM ss
 UNION ALL
 SELECT * FROM ws
),
ranked AS (
 SELECT
   d_year,
   month,
   i_category,
   i_brand,
   p_promo_id,
   country,
   total_sales,
   total_discount,
   total_ship_cost,
   total_profit,
   order_count,
   ROW_NUMBER() OVER (PARTITION BY d_year, month, country ORDER BY total_profit DESC) AS profit_rank
 FROM combined
)
SELECT
 d_year,
 month,
 i_category,
 i_brand,
 p_promo_id,
 country,
 total_sales,
 total_discount,
 total_ship_cost,
 total_profit,
 order_count,
 profit_rank
FROM ranked
WHERE profit_rank <= 5
ORDER BY d_year, month, country, profit_rank
