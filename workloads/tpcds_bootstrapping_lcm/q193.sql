SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    t.t_hour,
    t.t_minute,
    t.t_shift,
    hd_ref.hd_buy_potential          AS refunded_buy_potential,
    hd_ret.hd_buy_potential          AS returning_buy_potential,
    s.s_store_name,
    s.s_state,
    COUNT(*)                         AS return_count,
    SUM(wr.wr_return_amt)            AS total_return_amount,
    SUM(wr.wr_net_loss)              AS total_net_loss,
    AVG(wr.wr_return_quantity)       AS avg_return_quantity,
    CASE 
        WHEN SUM(wr.wr_return_amt) = 0 THEN NULL
        ELSE SUM(wr.wr_net_loss) / SUM(wr.wr_return_amt)
    END                              AS net_loss_ratio
FROM date_dim AS d
JOIN web_returns AS wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN time_dim AS t
    ON wr.wr_returned_time_sk = t.t_time_sk
JOIN household_demographics AS hd_ref
    ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics AS hd_ret
    ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN store AS s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE s.s_closed_date_sk IS NOT NULL
GROUP BY
    d.d_date,
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    t.t_hour,
    t.t_minute,
    t.t_shift,
    hd_ref.hd_buy_potential,
    hd_ret.hd_buy_potential,
    s.s_store_name,
    s.s_state
ORDER BY total_net_loss DESC
LIMIT 100
