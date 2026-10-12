SELECT d.d_year,
       p.p_promo_name,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       AVG(ss.ss_net_profit) AS avg_profit
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_year = 1919
  AND p.p_discount_active = 'N'
GROUP BY d.d_year, p.p_promo_name
