SELECT
    d.d_year,
    i.i_category,
    s.s_state,
    p.p_promo_name,
    SUM(ss.ss_net_paid_inc_tax) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS orders,
    AVG(ss.ss_quantity) AS avg_quantity
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_year = 1999
  AND s.s_state IN ('TX', 'CA', 'NY')
GROUP BY d.d_year, i.i_category, s.s_state, p.p_promo_name
ORDER BY total_sales DESC
LIMIT 50
