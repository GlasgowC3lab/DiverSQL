SELECT
    COALESCE(d_ret.d_year, -1) AS year,
    COALESCE(d_ret.d_month_seq, -1) AS month_seq,
    COALESCE(s.s_store_id, 'ALL') AS store_id,
    COALESCE(s.s_state, 'ALL') AS state,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    SUM(i.inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_store_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_web_orders,
    AVG(sr.sr_return_quantity) AS avg_store_return_qty,
    AVG(wr.wr_return_quantity) AS avg_web_return_qty
FROM
    date_dim d_ret
    JOIN store_returns sr ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store s ON s.s_store_sk = sr.sr_store_sk
    JOIN inventory i ON i.inv_date_sk = d_ret.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE
    d_ret.d_year = 2022
    AND s.s_state = 'CA'
    AND i.inv_quantity_on_hand > 0
GROUP BY ROLLUP (d_ret.d_year, d_ret.d_month_seq, s.s_store_id, s.s_state)
HAVING
    SUM(sr.sr_net_loss) > 10000
ORDER BY
    total_store_return_loss DESC
LIMIT 100
