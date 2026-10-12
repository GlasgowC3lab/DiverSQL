WITH ca_store AS (
   SELECT s_store_sk, s_store_name, s_state
   FROM store
   WHERE s_state = 'CA'
), promo_keys AS (
   SELECT p_promo_sk
   FROM promotion
   WHERE p_discount_active = 'Y' AND p_promo_name LIKE '%Summer%'
), promo_excluded AS (
   SELECT p_promo_sk
   FROM promotion
   WHERE p_promo_name LIKE '%Clearance%'
), promo_final AS (
   SELECT p_promo_sk
   FROM promo_keys
   EXCEPT
   SELECT p_promo_sk
   FROM promo_excluded
)
SELECT
   d.d_date,
   s.s_store_name,
   CASE WHEN ss.ss_quantity > 5 THEN 'Large' ELSE 'Small' END AS quantity_category,
   COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
   SUM(ss.ss_net_paid) AS total_store_net_paid,
   AVG(cs.cs_ext_sales_price) AS avg_catalog_ext_sales,
   MIN(ss.ss_net_paid) AS min_store_net_paid,
   MAX(ss.ss_net_paid) AS max_store_net_paid
FROM
   catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
WHERE
   d.d_year = 2001
   AND d.d_month_seq BETWEEN 1200 AND 1210
   AND d.d_day_name = 'Saturday'
   AND cp.cp_type = 'Standard'
   AND wp.wp_char_count BETWEEN 1000 AND 5000
   AND p.p_promo_sk IN (SELECT p_promo_sk FROM promo_final)
   AND s.s_store_sk IN (SELECT s_store_sk FROM ca_store)
GROUP BY
   d.d_date,
   s.s_store_name,
   CASE WHEN ss.ss_quantity > 5 THEN 'Large' ELSE 'Small' END
ORDER BY
   total_store_net_paid DESC
LIMIT 100
