SELECT
    d_ret.d_date AS return_date,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_store.d_date AS store_closed_date,
    s.s_store_name,
    s.s_state,
    s.s_tax_percentage,
    ws.web_name,
    ws.web_state,
    d_open.d_date AS site_open_date,
    d_close.d_date AS site_close_date,
    hd_refunded.hd_buy_potential AS refunded_buy_potential,
    hd_returning.hd_buy_potential AS returning_buy_potential,
    COUNT(DISTINCT wr.wr_order_number) AS num_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_fee) AS total_fees,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    ROUND(AVG(wr.wr_return_amt_inc_tax - wr.wr_return_tax), 2) AS avg_return_amount_excl_tax
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN household_demographics hd_refunded
    ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_ret.d_date_sk
JOIN date_dim d_open
    ON ws.web_open_date_sk = d_open.d_date_sk
JOIN date_dim d_close
    ON ws.web_close_date_sk = d_close.d_date_sk
WHERE d_ret.d_year = 2022
GROUP BY
    d_ret.d_date,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_store.d_date,
    s.s_store_name,
    s.s_state,
    s.s_tax_percentage,
    ws.web_name,
    ws.web_state,
    d_open.d_date,
    d_close.d_date,
    hd_refunded.hd_buy_potential,
    hd_returning.hd_buy_potential
ORDER BY total_return_amount DESC
LIMIT 100
