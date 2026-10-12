SELECT i.i_category,
       SUM(CASE WHEN d.d_year = 1998 THEN ss.ss_net_profit END) AS profit_1998,
       SUM(CASE WHEN d.d_year = 1999 THEN ss.ss_net_profit END) AS profit_1999,
       SUM(CASE WHEN d.d_year = 1998 THEN ss.ss_net_profit END) - SUM(CASE WHEN d.d_year = 1999 THEN ss.ss_net_profit END) AS profit_change
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_year IN (1998, 1999)
  AND p.p_discount_active = 'Y'
GROUP BY i.i_category
ORDER BY profit_change DESC
LIMIT 10
