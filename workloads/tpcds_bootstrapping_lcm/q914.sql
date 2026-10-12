SELECT
    cp.cp_department,
    cp.cp_type,
    d_end.d_year,
    s.s_state,
    CASE
        WHEN s.s_floor_space >= 20000 THEN 'Mega'
        WHEN s.s_floor_space >= 10000 THEN 'Large'
        ELSE 'Small'
    END AS store_size_category,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets,
    COALESCE(SUM(sr.sr_net_loss), 0) AS total_store_net_loss,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_web_net_loss,
    COALESCE(SUM(CASE WHEN sr.sr_return_quantity > 0 THEN sr.sr_return_quantity * sr.sr_return_amt_inc_tax ELSE 0 END), 0) AS store_return_amount,
    COALESCE(SUM(CASE WHEN wr.wr_return_quantity > 0 THEN wr.wr_return_quantity * wr.wr_return_amt_inc_tax ELSE 0 END), 0) AS web_return_amount,
    ROUND(
        100.0 * COALESCE(SUM(sr.sr_net_loss), 0) /
        NULLIF(COALESCE(SUM(sr.sr_net_loss), 0) + COALESCE(SUM(wr.wr_net_loss), 0), 0),
        2
    ) AS store_net_loss_pct,
    ROUND(
        100.0 * COALESCE(SUM(wr.wr_net_loss), 0) /
        NULLIF(COALESCE(SUM(sr.sr_net_loss), 0) + COALESCE(SUM(wr.wr_net_loss), 0), 0),
        2
    ) AS web_net_loss_pct
FROM catalog_page cp
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d_start.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_end.d_date_sk
WHERE d_end.d_year = 2022
GROUP BY
    cp.cp_department,
    cp.cp_type,
    d_end.d_year,
    s.s_state,
    CASE
        WHEN s.s_floor_space >= 20000 THEN 'Mega'
        WHEN s.s_floor_space >= 10000 THEN 'Large'
        ELSE 'Small'
    END
HAVING COALESCE(SUM(sr.sr_net_loss), 0) + COALESCE(SUM(wr.wr_net_loss), 0) > 0
ORDER BY total_store_net_loss DESC
LIMIT 100
