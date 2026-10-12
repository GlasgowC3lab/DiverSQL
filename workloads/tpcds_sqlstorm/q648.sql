SELECT d.d_year AS year,
       s.s_state AS state,
       i.i_category AS category,
       cd.cd_gender AS gender,
       p.p_promo_name AS promo_name,
       SUM(ss.ss_net_paid) AS total_net_paid,
       SUM(ss.ss_net_profit) AS total_net_profit,
       COUNT(*) AS sales_cnt,
       AVG(ss.ss_quantity) AS avg_quantity
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_year BETWEEN 2000 AND 2002
  AND s.s_state IN ('TX', 'CA', 'NY')
  AND p.p_discount_active = 'Y'
GROUP BY d.d_year, s.s_state, i.i_category, cd.cd_gender, p.p_promo_name
ORDER BY total_net_paid DESC
LIMIT 100
