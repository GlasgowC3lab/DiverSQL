SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state AS store_state,
    ds.d_date AS store_closed_date,
    ws.web_site_id,
    ws.web_name,
    ws.web_city,
    dw_open.d_date AS site_open_date,
    dw_close.d_date AS site_close_date,
    dr.d_date AS return_date,
    dr.d_year,
    dr.d_month_seq,
    dr.d_day_name,
    t.t_hour,
    t.t_meal_time,
    t.t_shift,
    COUNT(*) AS return_cnt,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    AVG(wr.wr_return_amt) AS avg_return_amt
FROM web_returns wr
JOIN date_dim dr
    ON wr.wr_returned_date_sk = dr.d_date_sk
JOIN time_dim t
    ON wr.wr_returned_time_sk = t.t_time_sk
CROSS JOIN store s
JOIN date_dim ds
    ON s.s_closed_date_sk = ds.d_date_sk
CROSS JOIN web_site ws
JOIN date_dim dw_open
    ON ws.web_open_date_sk = dw_open.d_date_sk
JOIN date_dim dw_close
    ON ws.web_close_date_sk = dw_close.d_date_sk
WHERE dr.d_date BETWEEN dw_open.d_date AND dw_close.d_date
  AND ds.d_date <= dr.d_date
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    ds.d_date,
    ws.web_site_id,
    ws.web_name,
    ws.web_city,
    dw_open.d_date,
    dw_close.d_date,
    dr.d_date,
    dr.d_year,
    dr.d_month_seq,
    dr.d_day_name,
    t.t_hour,
    t.t_meal_time,
    t.t_shift
ORDER BY total_net_loss DESC
LIMIT 100
