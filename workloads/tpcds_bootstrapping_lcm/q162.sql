SELECT
    s.s_store_id,
    s.s_store_name,
    d_ret.d_year,
    hd_store.hd_buy_potential,
    hd_web.hd_income_band_sk,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(sr.sr_return_quantity) AS total_store_return_qty,
    SUM(wr.wr_return_quantity) AS total_web_return_qty,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    CASE
        WHEN d_closed.d_date IS NULL THEN 'Open'
        ELSE 'Closed'
    END AS store_status,
    d_closed.d_date AS store_closed_date
FROM store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN household_demographics hd_store
    ON sr.sr_hdemo_sk = hd_store.hd_demo_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN household_demographics hd_web
    ON wr.wr_refunded_hdemo_sk = hd_web.hd_demo_sk
WHERE d_ret.d_year BETWEEN 2000 AND 2020
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_ret.d_year,
    hd_store.hd_buy_potential,
    hd_web.hd_income_band_sk,
    d_closed.d_date
ORDER BY total_store_net_loss DESC, total_web_net_loss DESC
LIMIT 100
