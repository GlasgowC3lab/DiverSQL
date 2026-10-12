SELECT
    d.d_year,
    d.d_quarter_name,
    s.s_state,
    s.s_store_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd_refunded.hd_buy_potential,
    hd_returning.hd_vehicle_count,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_fee) AS total_fees,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) / NULLIF(s.s_floor_space, 0) AS return_per_sqft,
    CASE
        WHEN SUM(wr.wr_net_loss) > 0 THEN 'Loss'
        WHEN SUM(wr.wr_net_loss) < 0 THEN 'Gain'
        ELSE 'Neutral'
    END AS net_loss_category
FROM date_dim d
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd_refunded
    ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN income_band ib
    ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
WHERE d.d_year = 2022
  AND d.d_holiday = 'N'
GROUP BY
    d.d_year,
    d.d_quarter_name,
    s.s_state,
    s.s_store_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd_refunded.hd_buy_potential,
    hd_returning.hd_vehicle_count,
    s.s_floor_space
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
