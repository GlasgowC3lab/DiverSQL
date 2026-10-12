SELECT
    cc.cc_market_manager,
    cc.cc_gmt_offset,
    s.s_market_manager,
    s.s_state,
    dr_return.d_year,
    dr_return.d_year - (dr_return.d_year % 10) AS decade,
    COUNT(*) AS total_returns,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
    CASE
        WHEN SUM(sr.sr_net_loss) > 50000 THEN 'HIGH'
        ELSE 'LOW'
    END AS loss_category
FROM store_returns AS sr
JOIN date_dim AS dr_return
    ON sr.sr_returned_date_sk = dr_return.d_date_sk
JOIN customer AS c
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN store AS s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim AS dr_store_closed
    ON s.s_closed_date_sk = dr_store_closed.d_date_sk
JOIN call_center AS cc
    ON cc.cc_closed_date_sk = dr_store_closed.d_date_sk
JOIN date_dim AS dr_cc_open
    ON cc.cc_open_date_sk = dr_cc_open.d_date_sk
WHERE dr_return.d_year >= 2000
  AND dr_cc_open.d_year = dr_return.d_year
GROUP BY
    cc.cc_market_manager,
    cc.cc_gmt_offset,
    s.s_market_manager,
    s.s_state,
    dr_return.d_year,
    dr_return.d_year - (dr_return.d_year % 10)
ORDER BY total_net_loss DESC
LIMIT 100
