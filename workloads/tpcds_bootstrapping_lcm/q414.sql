SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d.d_year AS closed_year,
    d.d_month_seq AS closed_month,
    d_open.d_year AS open_year,
    MAX(date_diff('day', d_open.d_date, d.d_date)) AS days_open_to_close,
    COUNT(DISTINCT wr.wr_order_number) AS return_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_tax) AS avg_return_tax,
    SUM(wr.wr_return_quantity) AS total_quantity
FROM date_dim d
JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
WHERE d.d_date >= d_open.d_date
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d.d_year,
    d.d_month_seq,
    d_open.d_year
HAVING SUM(wr.wr_return_amt) > 500
ORDER BY total_return_amount DESC
LIMIT 100
