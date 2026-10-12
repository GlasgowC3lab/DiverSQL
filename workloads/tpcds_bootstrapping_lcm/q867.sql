SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    d_cl.d_year AS store_closed_year,
    s.s_store_id,
    s.s_state,
    hd_sr.hd_income_band_sk,
    hd_sr.hd_vehicle_count,
    hd_wr.hd_buy_potential,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    SUM(sr.sr_fee) AS total_store_fee,
    SUM(wr.wr_fee) AS total_web_fee,
    SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders
FROM store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_cl
    ON s.s_closed_date_sk = d_cl.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN household_demographics hd_wr
    ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    d_cl.d_year,
    s.s_store_id,
    s.s_state,
    hd_sr.hd_income_band_sk,
    hd_sr.hd_vehicle_count,
    hd_wr.hd_buy_potential
ORDER BY total_net_loss DESC
LIMIT 100
