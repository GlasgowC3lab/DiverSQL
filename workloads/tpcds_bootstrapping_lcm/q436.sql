SELECT
    d_sales.d_year,
    d_sales.d_month_seq,
    s.s_store_name,
    s.s_city,
    p.p_promo_name,
    p.p_channel_email,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    d_store_closed.d_date AS store_closed_date,
    CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END AS discount_active_flag,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) AS total_return_amount,
    (SUM(ss.ss_ext_sales_price) - COALESCE(SUM(wr.wr_return_amt_inc_tax), 0)) AS net_sales_amount
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sales.d_date_sk
GROUP BY
    d_sales.d_year,
    d_sales.d_month_seq,
    s.s_store_name,
    s.s_city,
    p.p_promo_name,
    p.p_channel_email,
    d_promo_start.d_date,
    d_promo_end.d_date,
    d_store_closed.d_date,
    p.p_discount_active
ORDER BY
    d_sales.d_year,
    d_sales.d_month_seq,
    s.s_store_name
LIMIT 100
