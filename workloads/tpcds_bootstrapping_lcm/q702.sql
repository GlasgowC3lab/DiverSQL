SELECT
    d.d_date,
    d.d_current_year,
    d.d_current_month,
    s.s_store_id,
    s.s_store_name,
    ws.web_site_id,
    ws.web_name,
    t.t_shift,
    t.t_hour,
    SUM(wr.wr_return_amt)                     AS total_return_amount,
    SUM(wr.wr_return_amt_inc_tax)             AS total_return_amount_inc_tax,
    SUM(wr.wr_net_loss)                       AS total_net_loss,
    AVG(wr.wr_return_quantity)                AS avg_return_quantity,
    COUNT(*)                                   AS return_count,
    CASE
        WHEN SUM(wr.wr_return_amt) = 0 THEN 0
        ELSE SUM(wr.wr_net_loss) / SUM(wr.wr_return_amt)
    END                                        AS net_loss_ratio,
    RANK() OVER (PARTITION BY d.d_date ORDER BY SUM(wr.wr_return_amt) DESC) AS store_rank_by_return
FROM date_dim d
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN time_dim t      ON wr.wr_returned_time_sk = t.t_time_sk
JOIN store s         ON s.s_closed_date_sk      = d.d_date_sk
JOIN web_site ws     ON ws.web_open_date_sk    = d.d_date_sk
WHERE d.d_year BETWEEN 2020 AND 2022
GROUP BY
    d.d_date,
    d.d_current_year,
    d.d_current_month,
    s.s_store_id,
    s.s_store_name,
    ws.web_site_id,
    ws.web_name,
    t.t_shift,
    t.t_hour
HAVING SUM(wr.wr_return_amt) > 0
ORDER BY d.d_date DESC, store_rank_by_return
LIMIT 100
