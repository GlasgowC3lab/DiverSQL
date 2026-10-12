SELECT
    d_return.d_year,
    d_return.d_month_seq,
    p.p_promo_name,
    p.p_discount_active,
    s.s_store_name,
    s.s_state,
    date_diff('day', d_return.d_date, d_end.d_date) AS promo_duration_days,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    AVG(wr.wr_return_tax) AS avg_return_tax,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    COUNT(*) AS total_returns
FROM web_returns wr
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_return.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
WHERE d_return.d_year BETWEEN 2015 AND 2020
  AND p.p_discount_active = 'Y'
GROUP BY
    d_return.d_year,
    d_return.d_month_seq,
    p.p_promo_name,
    p.p_discount_active,
    s.s_store_name,
    s.s_state,
    d_return.d_date,
    d_end.d_date
ORDER BY total_return_amount DESC
LIMIT 100
