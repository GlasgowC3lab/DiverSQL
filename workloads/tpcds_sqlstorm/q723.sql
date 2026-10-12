SELECT s.s_state,
       i.i_category,
       p.p_promo_name,
       sum(ss.ss_net_paid) AS total_sales,
       sum(ss.ss_net_profit) AS total_profit
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_year = 2000
GROUP BY s.s_state, i.i_category, p.p_promo_name
ORDER BY total_sales DESC
LIMIT 10
