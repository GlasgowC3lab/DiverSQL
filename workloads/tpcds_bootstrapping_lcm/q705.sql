SELECT
    ds.d_date AS sale_date,
    ds.d_year,
    ds.d_month_seq,
    s.s_store_id,
    s.s_city,
    s.s_state,
    p.p_promo_name,
    p.p_channel_tv,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT wp.wp_web_page_id) AS web_pages_created,
    COUNT(DISTINCT ss.ss_ticket_number) AS tickets_sold,
    AVG(p.p_cost) AS avg_promo_cost,
    dstore.d_holiday AS store_closed_holiday,
    dp_start.d_current_month AS promo_start_month,
    dp_end.d_current_month AS promo_end_month
FROM store_sales ss
JOIN date_dim ds
    ON ss.ss_sold_date_sk = ds.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = ds.d_date_sk
LEFT JOIN date_dim dstore
    ON s.s_closed_date_sk = dstore.d_date_sk
LEFT JOIN date_dim dp_start
    ON p.p_start_date_sk = dp_start.d_date_sk
LEFT JOIN date_dim dp_end
    ON p.p_end_date_sk = dp_end.d_date_sk
WHERE ds.d_year = 2022
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
GROUP BY
    ds.d_date,
    ds.d_year,
    ds.d_month_seq,
    s.s_store_id,
    s.s_city,
    s.s_state,
    p.p_promo_name,
    p.p_channel_tv,
    dstore.d_holiday,
    dp_start.d_current_month,
    dp_end.d_current_month
ORDER BY total_sales DESC
LIMIT 100
