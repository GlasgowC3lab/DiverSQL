SELECT
    d.d_year,
    i.i_category,
    s.s_state,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_orders,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(p.p_cost) AS avg_promo_cost
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_year BETWEEN 1999 AND 2002
  AND s.s_state IN ('CA','TX','WA')
  AND i.i_category IN ('Women','Men')
  AND p.p_discount_active = 'Y'
GROUP BY d.d_year, i.i_category, s.s_state
ORDER BY d.d_year, total_sales DESC
