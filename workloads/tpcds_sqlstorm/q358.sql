SELECT
    s.s_store_name,
    d.d_year,
    cd.cd_gender,
    i.i_category,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold,
    AVG(ss.ss_quantity) AS avg_quantity_per_sale,
    SUM(COALESCE(p.p_cost, 0)) AS total_promo_cost
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_year BETWEEN 2000 AND 2002
  AND s.s_state = 'CA'
GROUP BY s.s_store_name, d.d_year, cd.cd_gender, i.i_category
ORDER BY total_net_profit DESC
LIMIT 100
