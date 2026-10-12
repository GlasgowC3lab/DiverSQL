SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    cp.cp_catalog_number,
    cp.cp_type,
    d_wr.d_year,
    d_wr.d_month_seq,
    COUNT(DISTINCT wr.wr_order_number) AS num_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(wr.wr_fee) AS total_fee,
    MIN(d_wr.d_date) AS first_return_date,
    MAX(d_wr.d_date) AS last_return_date,
    d_cp_start.d_date AS catalog_start_date,
    d_cp_end.d_date AS catalog_end_date,
    s.s_closed_date_sk AS store_closed_date_sk
FROM web_returns wr
JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN catalog_page cp
    ON wr.wr_returned_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_wr.d_date_sk
WHERE d_wr.d_year >= 2020
GROUP BY
    s.s_store_id,
    s.s_city,
    s.s_state,
    cp.cp_catalog_number,
    cp.cp_type,
    d_wr.d_year,
    d_wr.d_month_seq,
    d_cp_start.d_date,
    d_cp_end.d_date,
    s.s_closed_date_sk
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
