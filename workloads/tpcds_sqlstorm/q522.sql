SELECT
    s.s_store_name,
    i.i_category,
    d.d_year,
    d.d_month_seq,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_ext_sales_price) AS total_ext_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    AVG(CASE WHEN ss.ss_ext_sales_price > 0 THEN ss.ss_ext_discount_amt / ss.ss_ext_sales_price END) AS avg_discount_ratio,
    SUM(ss.ss_net_profit) AS total_net_profit
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_year = 2000
GROUP BY
    s.s_store_name,
    i.i_category,
    d.d_year,
    d.d_month_seq
ORDER BY
    total_net_profit DESC
LIMIT 100
