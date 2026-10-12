SELECT d.d_year,
       s.s_state,
       i.i_category,
       SUM(ss.ss_net_profit) AS total_net_profit,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       COUNT(*) AS sales_cnt,
       AVG(ss.ss_quantity) AS avg_quantity,
       COUNT(DISTINCT c.c_customer_sk) AS distinct_customers
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND i.i_category = 'Electronics'
  AND (p.p_channel_tv = 'Y' OR p.p_channel_tv IS NULL)
GROUP BY d.d_year, s.s_state, i.i_category
ORDER BY total_net_profit DESC
LIMIT 100
