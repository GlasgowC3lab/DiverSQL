SELECT
    d_return.d_year,
    d_return.d_quarter_name,
    d_return.d_month_seq,
    CASE WHEN d_return.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
    s.s_store_name,
    s.s_state,
    d_closed.d_date AS store_closed_date,
    ws.web_name,
    ws.web_state,
    d_web_close.d_date AS web_close_date,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt,
    SUM(sr.sr_net_loss) AS store_net_loss,
    SUM(wr.wr_net_loss) AS web_net_loss,
    SUM(sr.sr_return_amt) AS store_return_amt,
    SUM(wr.wr_return_amt) AS web_return_amt,
    (SUM(sr.sr_return_amt) - SUM(wr.wr_return_amt)) AS return_amt_diff,
    SUM(sr.sr_return_quantity) AS store_return_qty,
    SUM(wr.wr_return_quantity) AS web_return_qty,
    (SUM(sr.sr_return_quantity) * 1.2) AS weighted_store_return_qty,
    CASE 
        WHEN SUM(sr.sr_return_amt) > 0 THEN SUM(sr.sr_net_loss) / SUM(sr.sr_return_amt)
        ELSE NULL
    END AS store_loss_ratio,
    CASE 
        WHEN SUM(wr.wr_return_amt) > 0 THEN SUM(wr.wr_net_loss) / SUM(wr.wr_return_amt)
        ELSE NULL
    END AS web_loss_ratio,
    CASE 
        WHEN (SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) > 50000 THEN 'High' 
        ELSE 'Low' 
    END AS loss_severity
FROM
    store_returns sr
    JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_return.d_date_sk
    LEFT JOIN date_dim d_web_close ON ws.web_close_date_sk = d_web_close.d_date_sk
WHERE
    d_return.d_year BETWEEN 2018 AND 2022
    AND s.s_state = 'CA'
    AND ws.web_state = 'CA'
GROUP BY
    d_return.d_year,
    d_return.d_quarter_name,
    d_return.d_month_seq,
    s.s_store_name,
    s.s_state,
    d_closed.d_date,
    ws.web_name,
    ws.web_state,
    d_web_close.d_date
HAVING
    (SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) > 0
ORDER BY
    d_return.d_year,
    half_year,
    s.s_store_name
