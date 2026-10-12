WITH sales_union AS (
 SELECT
   ss_sold_date_sk AS date_sk,
   ss_item_sk AS item_sk,
   ss_store_sk AS channel_sk,
   'store' AS channel,
   ss_quantity AS quantity,
   ss_net_paid AS net_paid,
   ss_net_profit AS net_profit,
   ss_customer_sk AS cust_sk,
   ss_promo_sk AS promo_sk
 FROM store_sales
 UNION ALL
 SELECT
   cs_sold_date_sk,
   cs_item_sk,
   cs_call_center_sk,
   'catalog' AS channel,
   cs_quantity,
   cs_net_paid,
   cs_net_profit,
   cs_bill_customer_sk,
   cs_promo_sk
 FROM catalog_sales
 UNION ALL
 SELECT
   ws_sold_date_sk,
   ws_item_sk,
   ws_web_page_sk,
   'web' AS channel,
   ws_quantity,
   ws_net_paid,
   ws_net_profit,
   ws_bill_customer_sk,
   ws_promo_sk
 FROM web_sales
),
joined_sales AS (
 SELECT
   su.*,
   d.d_year,
   d.d_quarter_seq,
   i.i_brand,
   i.i_category,
   p.p_discount_active,
   c.c_preferred_cust_flag,
   cd.cd_gender,
   cc.cc_name AS call_center_name,
   st.s_store_name AS store_name,
   wp.wp_url AS web_page_url
 FROM sales_union su
 JOIN date_dim d ON su.date_sk = d.d_date_sk
 JOIN item i ON su.item_sk = i.i_item_sk
 LEFT JOIN promotion p ON su.promo_sk = p.p_promo_sk
 LEFT JOIN customer c ON su.cust_sk = c.c_customer_sk
 LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
 LEFT JOIN call_center cc ON su.channel = 'catalog' AND su.channel_sk = cc.cc_call_center_sk
 LEFT JOIN store st ON su.channel = 'store' AND su.channel_sk = st.s_store_sk
 LEFT JOIN web_page wp ON su.channel = 'web' AND su.channel_sk = wp.wp_web_page_sk
 WHERE (p.p_discount_active = 'Y' OR p.p_promo_sk IS NULL)
   AND (cd.cd_gender = 'M' OR cd.cd_gender IS NULL)
),
agg_sales AS (
 SELECT
   d_year,
   d_quarter_seq,
   i_brand,
   i_category,
   channel,
   COALESCE(call_center_name, store_name, web_page_url) AS channel_detail,
   SUM(net_paid) AS total_net_paid,
   SUM(net_profit) AS total_net_profit,
   COUNT(DISTINCT cust_sk) AS distinct_customers,
   SUM(net_profit) / NULLIF(SUM(net_paid), 0) AS profit_margin_ratio
 FROM joined_sales
 GROUP BY
   d_year,
   d_quarter_seq,
   i_brand,
   i_category,
   channel,
   COALESCE(call_center_name, store_name, web_page_url)
),
final AS (
 SELECT
   d_year,
   d_quarter_seq,
   i_brand,
   i_category,
   channel,
   channel_detail,
   total_net_paid,
   total_net_profit,
   distinct_customers,
   profit_margin_ratio,
   total_net_paid / SUM(total_net_paid) OVER (PARTITION BY d_year) AS revenue_share,
   RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS revenue_rank
 FROM agg_sales
)
SELECT *
FROM final
WHERE revenue_rank <= 10
ORDER BY d_year, revenue_rank
