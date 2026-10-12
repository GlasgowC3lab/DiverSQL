SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    t.t_hour,
    t.t_minute,
    s.s_market_desc,
    s.s_state,
    COUNT(cr.cr_order_number) AS catalog_return_cnt,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    COUNT(wr.wr_order_number) AS web_return_cnt,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss,
    ROUND(AVG(cr.cr_return_quantity), 2) AS avg_catalog_return_qty,
    ROUND(AVG(wr.wr_return_quantity), 2) AS avg_web_return_qty,
    (SUM(cr.cr_return_amount) + SUM(wr.wr_return_amt)) AS total_return_amount,
    (SUM(cr.cr_return_tax) + SUM(wr.wr_return_tax)) AS total_return_tax
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_returned_time_sk = t.t_time_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY
    d.d_date,
    d.d_year,
    d.d_month_seq,
    t.t_hour,
    t.t_minute,
    s.s_market_desc,
    s.s_state
ORDER BY total_net_loss DESC
LIMIT 100
