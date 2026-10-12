SELECT
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    s.s_state,
    s.s_city,
    cp.cp_department,
    cp.cp_type,
    r.r_reason_desc,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_quantity) AS total_quantity,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_refunded_cash) AS total_refunded_cash,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    ROUND((SUM(wr.wr_net_loss) / NULLIF(SUM(wr.wr_return_amt), 0)) * 100, 2) AS net_loss_percent
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2020 AND 2022
  AND s.s_state = 'CA'
GROUP BY
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    s.s_state,
    s.s_city,
    cp.cp_department,
    cp.cp_type,
    r.r_reason_desc
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
