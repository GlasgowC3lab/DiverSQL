SELECT
    c.cc_market_manager,
    s.s_state,
    CASE WHEN d_month.d_month_seq % 2 = 0 THEN 'EvenMonth' ELSE 'OddMonth' END AS month_parity,
    p.p_channel_tv,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT c.cc_call_center_sk) AS unique_call_center_count,
    COUNT(DISTINCT s.s_store_sk) AS unique_store_count,
    SUM(p.p_cost) AS total_promotion_cost,
    AVG(s.s_floor_space) AS avg_store_floor_space,
    AVG(CAST(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END AS double)) AS promo_discount_active_rate,
    date_diff('day', dp_start.d_date, dp_end.d_date) AS promo_duration_days
FROM call_center c
JOIN date_dim d_closed ON c.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open ON c.cc_open_date_sk = d_open.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_closed.d_date_sk
JOIN date_dim dp_start ON p.p_start_date_sk = dp_start.d_date_sk
JOIN date_dim dp_end ON p.p_end_date_sk = dp_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_month ON d_closed.d_date_sk = d_month.d_date_sk
GROUP BY
    c.cc_market_manager,
    s.s_state,
    CASE WHEN d_month.d_month_seq % 2 = 0 THEN 'EvenMonth' ELSE 'OddMonth' END,
    p.p_channel_tv,
    date_diff('day', dp_start.d_date, dp_end.d_date)
HAVING SUM(p.p_cost) > 0
ORDER BY total_promotion_cost DESC
LIMIT 100
