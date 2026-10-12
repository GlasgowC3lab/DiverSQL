WITH sales_base AS (
   SELECT
       s.s_store_id,
       p.p_promo_name,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       SUM(ss.ss_ext_sales_price) AS total_sales
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE p.p_promo_name LIKE '%Discount%'
     AND regexp_like(p.p_promo_name, '[0-9]{2}')
     AND regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
   GROUP BY s.s_store_id, p.p_promo_name, ib.ib_lower_bound, ib.ib_upper_bound
   HAVING SUM(ss.ss_ext_sales_price) > 100000
),

sales_ranked AS (
   SELECT
       s_store_id,
       p_promo_name,
       ib_lower_bound,
       ib_upper_bound,
       total_sales,
       ROW_NUMBER() OVER (PARTITION BY p_promo_name ORDER BY total_sales DESC) AS sales_rank
   FROM sales_base
),

returns_store AS (
   SELECT DISTINCT s.s_store_id
   FROM store_returns sr
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
),

high_sales_no_returns AS (
   SELECT s_store_id
   FROM sales_ranked
   EXCEPT
   SELECT s_store_id FROM returns_store
)

SELECT
   sr.s_store_id,
   sr.p_promo_name,
   CONCAT(sr.p_promo_name, '_', CAST(sr.total_sales AS VARCHAR)) AS promo_sales_label,
   SUBSTRING(sr.p_promo_name FROM 1 FOR 10) AS promo_name_prefix,
   regexp_extract(sr.p_promo_name, '(\\d{2})', 1) AS promo_two_digit_code,
   sr.total_sales,
   sr.sales_rank
FROM sales_ranked sr
JOIN high_sales_no_returns hs ON sr.s_store_id = hs.s_store_id
ORDER BY sr.total_sales DESC
LIMIT 100
