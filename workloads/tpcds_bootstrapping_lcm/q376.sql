SELECT
    s.s_state,
    dr.d_year AS return_year,
    dr.d_month_seq AS return_month,
    p.p_promo_id,
    p.p_promo_name,
    ds.d_year AS promo_start_year,
    de.d_year AS promo_end_year,
    date_diff('day', ds.d_date, de.d_date) + 1 AS promo_duration_days,
    CASE
        WHEN date_diff('day', ds.d_date, de.d_date) + 1 > 180 THEN 'Long'
        ELSE 'Short'
    END AS promo_duration_category,
    t.t_shift,
    CASE
        WHEN s.s_floor_space >= 100000 THEN 'Large'
        WHEN s.s_floor_space >= 50000 THEN 'Medium'
        ELSE 'Small'
    END AS store_size_category,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(p.p_cost) AS avg_promo_cost,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN wr.wr_return_amt ELSE 0 END) AS discount_active_return_amt
FROM web_returns wr
JOIN date_dim dr
    ON wr.wr_returned_date_sk = dr.d_date_sk
JOIN time_dim t
    ON wr.wr_returned_time_sk = t.t_time_sk
JOIN store s
    ON s.s_closed_date_sk = dr.d_date_sk
CROSS JOIN promotion p
JOIN date_dim ds
    ON p.p_start_date_sk = ds.d_date_sk
JOIN date_dim de
    ON p.p_end_date_sk = de.d_date_sk
WHERE dr.d_date BETWEEN ds.d_date AND de.d_date
GROUP BY
    s.s_state,
    dr.d_year,
    dr.d_month_seq,
    p.p_promo_id,
    p.p_promo_name,
    ds.d_year,
    de.d_year,
    date_diff('day', ds.d_date, de.d_date) + 1,
    CASE
        WHEN date_diff('day', ds.d_date, de.d_date) + 1 > 180 THEN 'Long'
        ELSE 'Short'
    END,
    t.t_shift,
    CASE
        WHEN s.s_floor_space >= 100000 THEN 'Large'
        WHEN s.s_floor_space >= 50000 THEN 'Medium'
        ELSE 'Small'
    END
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amt DESC
LIMIT 100
