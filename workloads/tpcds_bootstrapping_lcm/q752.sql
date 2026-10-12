SELECT
    cp.cp_catalog_page_id,
    cp.cp_description,
    d_start.d_date AS page_start_date,
    d_end.d_date AS page_end_date,
    date_diff('day', d_start.d_date, d_end.d_date) AS page_duration_days,
    COUNT(DISTINCT s.s_store_id) AS stores_closed_on_end_date,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    COUNT(*) AS total_joined_rows
FROM catalog_page cp
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d_end.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_end.d_date_sk
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_description,
    d_start.d_date,
    d_end.d_date
ORDER BY total_return_amount DESC
LIMIT 100
