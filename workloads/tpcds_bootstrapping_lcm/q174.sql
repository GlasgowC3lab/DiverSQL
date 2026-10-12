SELECT
    cc.cc_name AS call_center_name,
    cc.cc_state AS call_center_state,
    d_open.d_year AS call_center_open_year,
    s.s_store_name AS store_name,
    s.s_state AS store_state,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    (d_ret.d_year * 100 + d_ret.d_month_seq) AS year_month_id,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    CASE WHEN SUM(wr.wr_return_amt) > 5000 THEN 'HIGH' ELSE 'LOW' END AS return_amount_category,
    SUM(wr.wr_return_amt * (1 + cc.cc_tax_percentage / 100)) AS return_amount_with_tax,
    SUM(wr.wr_return_amt) - SUM(wr.wr_fee) AS net_return_without_fee
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
WHERE d_ret.d_year BETWEEN 2015 AND 2020
GROUP BY
    cc.cc_name,
    cc.cc_state,
    d_open.d_year,
    s.s_store_name,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    (d_ret.d_year * 100 + d_ret.d_month_seq)
HAVING COUNT(*) > 5
ORDER BY total_return_amount DESC
LIMIT 100
