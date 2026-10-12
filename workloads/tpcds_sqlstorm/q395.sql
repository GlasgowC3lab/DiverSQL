SELECT s.s_state,
       d.d_year,
       i.i_category,
       SUM(ss.ss_net_profit) AS total_net_profit,
       COUNT(*) AS sales_transactions,
       SUM(ss.ss_quantity) AS total_quantity,
       AVG(ss.ss_ext_discount_amt) AS avg_discount_amount
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_year BETWEEN 1999 AND 2002
  AND p.p_discount_active = 'Y'
  AND i.i_category = 'Sports'
GROUP BY s.s_state, d.d_year, i.i_category
ORDER BY total_net_profit DESC
LIMIT 100
