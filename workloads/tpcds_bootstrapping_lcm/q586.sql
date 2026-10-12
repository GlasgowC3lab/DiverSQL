SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    s.s_division_id AS division_id,
    s.s_state AS store_state,
    ws.web_state AS site_state,
    ws.web_country AS site_country,
    hd_ret.hd_income_band_sk AS returning_income_band,
    hd_ref.hd_income_band_sk AS refunded_income_band,
    hd_ret.hd_buy_potential AS returning_buy_potential,
    hd_ref.hd_buy_potential AS refunded_buy_potential,
    (hd_ret.hd_income_band_sk - hd_ref.hd_income_band_sk) AS income_band_diff,
    d_close.d_year AS site_close_year,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_inc_tax,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_return_ship_cost) AS total_ship_cost,
    CASE
        WHEN SUM(wr.wr_net_loss) > 5000 THEN 'High'
        ELSE 'Low'
    END AS loss_category,
    ROUND(SUM(wr.wr_net_loss) / NULLIF(SUM(wr.wr_return_amt), 0), 4) AS loss_ratio
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN household_demographics hd_ret
    ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN household_demographics hd_ref
    ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_ret.d_date_sk
JOIN date_dim d_close
    ON ws.web_close_date_sk = d_close.d_date_sk
WHERE d_ret.d_year >= 2000
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_division_id,
    s.s_state,
    ws.web_state,
    ws.web_country,
    hd_ret.hd_income_band_sk,
    hd_ref.hd_income_band_sk,
    hd_ret.hd_buy_potential,
    hd_ref.hd_buy_potential,
    d_close.d_year
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
