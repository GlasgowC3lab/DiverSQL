SELECT
    s.s_store_name,
    s.s_state,
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_brand,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(DISTINCT ss.ss_ticket_number) AS order_count,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    SUM(CASE WHEN p.p_promo_id IS NOT NULL THEN ss.ss_ext_sales_price * 0.9 ELSE ss.ss_ext_sales_price END) AS promo_sales_estimate
FROM
    store_sales ss
JOIN
    date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
JOIN
    store s
        ON ss.ss_store_sk = s.s_store_sk
JOIN
    item i
        ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN
    promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
WHERE
    d.d_year = 2001
    AND i.i_category = 'Books'
GROUP BY
    s.s_store_name,
    s.s_state,
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_brand
ORDER BY
    total_net_profit DESC
LIMIT 100
