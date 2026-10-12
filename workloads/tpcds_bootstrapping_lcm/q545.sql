SELECT
    d.d_date,
    d.d_current_week,
    d.d_year,
    s.s_state,
    s.s_market_desc,
    s.s_store_name,
    t.t_hour,
    t.t_meal_time,
    hd_ref.hd_buy_potential AS refunded_buy_potential,
    hd_ref.hd_income_band_sk AS refunded_income_band,
    hd_ret.hd_buy_potential AS returning_buy_potential,
    hd_ret.hd_income_band_sk AS returning_income_band,
    COUNT(*) AS total_returns,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(wr.wr_return_tax) AS total_return_tax,
    ROUND(
        (SUM(wr.wr_return_amt) - SUM(wr.wr_return_tax))
        / NULLIF(SUM(wr.wr_return_quantity), 0),
        2
    ) AS avg_net_per_item
FROM web_returns wr
JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON wr.wr_returned_time_sk = t.t_time_sk
JOIN household_demographics hd_ref
    ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret
    ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2016 AND 2020
GROUP BY
    d.d_date,
    d.d_current_week,
    d.d_year,
    s.s_state,
    s.s_market_desc,
    s.s_store_name,
    t.t_hour,
    t.t_meal_time,
    hd_ref.hd_buy_potential,
    hd_ref.hd_income_band_sk,
    hd_ret.hd_buy_potential,
    hd_ret.hd_income_band_sk
ORDER BY total_return_amount DESC
LIMIT 100
