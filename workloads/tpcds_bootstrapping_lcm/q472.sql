SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    ws.web_site_id,
    ws.web_name,
    ws.web_state,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_net_loss) AS total_net_loss,
    MIN(d_ret.d_date) AS first_return_date,
    MAX(d_ret.d_date) AS last_return_date,
    d_store.d_date AS store_closed_date,
    d_open.d_date AS site_open_date,
    d_close.d_date AS site_close_date
FROM web_returns wr
JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
CROSS JOIN web_site ws
JOIN date_dim d_open ON ws.web_open_date_sk = d_open.d_date_sk
JOIN date_dim d_close ON ws.web_close_date_sk = d_close.d_date_sk
WHERE d_ret.d_date BETWEEN d_open.d_date AND d_close.d_date
  AND d_ret.d_year = d_store.d_year
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    ws.web_site_id,
    ws.web_name,
    ws.web_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_store.d_date,
    d_open.d_date,
    d_close.d_date
ORDER BY total_return_amount DESC
LIMIT 100
