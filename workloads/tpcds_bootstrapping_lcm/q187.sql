SELECT
    d.d_year,
    d.d_month_seq,
    CASE WHEN p.p_discount_active = 'Y' THEN 'ACTIVE' ELSE 'INACTIVE' END AS promotion_status,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    AVG(hd_refunded.hd_income_band_sk) AS avg_income_band_refunded,
    AVG(hd_returning.hd_vehicle_count) AS avg_vehicle_count_returning,
    SUM(CASE WHEN s.s_state = 'CA' THEN wr.wr_return_amt ELSE 0 END) AS ca_return_amount,
    COUNT(*) FILTER (WHERE p.p_channel_tv = 'Y') AS tv_promotion_count,
    COUNT(*) FILTER (WHERE s.s_floor_space > 20000) AS large_store_count
FROM date_dim d
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd_refunded
    ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
   AND p.p_end_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
GROUP BY
    d.d_year,
    d.d_month_seq,
    CASE WHEN p.p_discount_active = 'Y' THEN 'ACTIVE' ELSE 'INACTIVE' END
ORDER BY d.d_year DESC, d.d_month_seq
LIMIT 100
