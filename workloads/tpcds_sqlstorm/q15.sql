SELECT s.s_store_name,
       p.p_promo_name,
       d.d_year,
       SUM(ss.ss_net_paid) AS total_sales,
       COUNT(*) AS order_cnt
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY s.s_store_name, p.p_promo_name, d.d_year
ORDER BY total_sales DESC
