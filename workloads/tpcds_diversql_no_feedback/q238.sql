WITH sales_promo AS (
    SELECT
        s.s_store_name,
        s.s_city,
        p.p_promo_name,
        regexp_extract(p.p_promo_name, '(\\d+)', 1) AS promo_code,
        d.d_year,
        ss.ss_net_paid
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE p.p_promo_name LIKE '%Clearance%'
      AND regexp_like(s.s_store_name, '^A.*')
      AND cd.cd_credit_rating = 'A'
)
SELECT
    s_store_name,
    s_city,
    promo_code,
    d_year,
    SUM(ss_net_paid) AS total_net_paid,
    COUNT(*) AS transaction_count,
    CONCAT('Store ', s_store_name, ' Promo ', COALESCE(promo_code, 'N/A')) AS description
FROM sales_promo
GROUP BY s_store_name, s_city, promo_code, d_year
HAVING SUM(ss_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
