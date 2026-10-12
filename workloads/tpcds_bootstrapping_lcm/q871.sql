SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    t.t_hour,
    CASE
        WHEN t.t_hour < 12 THEN 'Morning'
        WHEN t.t_hour < 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS time_of_day,
    s.s_store_name,
    s.s_state,
    hd_refunded.hd_buy_potential AS refunded_buy_potential,
    hd_returning.hd_buy_potential AS returning_buy_potential,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_net_loss) AS total_net_loss
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
JOIN household_demographics hd_refunded ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
GROUP BY
    d.d_date,
    d.d_year,
    d.d_month_seq,
    t.t_hour,
    s.s_store_name,
    s.s_state,
    hd_refunded.hd_buy_potential,
    hd_returning.hd_buy_potential
HAVING SUM(wr.wr_return_amt) > 500
ORDER BY d.d_date DESC, total_return_amount DESC
LIMIT 100
