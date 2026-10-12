SELECT
    s.s_store_name,
    s.s_city AS store_city,
    s.s_floor_space,
    cc.cc_name AS call_center_name,
    cc.cc_city AS call_center_city,
    p.p_promo_name,
    d_ret.d_year AS return_year,
    d_ret.d_current_month AS return_month,
    date_diff('day', d_ret.d_date, d_promo_end.d_date) AS days_to_promo_end,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_inc_tax,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    (SUM(wr.wr_net_loss) / NULLIF(s.s_floor_space, 0)) AS net_loss_per_sqft
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ret.d_date_sk
WHERE s.s_floor_space > 0
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_floor_space,
    cc.cc_name,
    cc.cc_city,
    p.p_promo_name,
    d_ret.d_year,
    d_ret.d_current_month,
    d_ret.d_date,
    d_promo_end.d_date
ORDER BY total_net_loss DESC
LIMIT 100
