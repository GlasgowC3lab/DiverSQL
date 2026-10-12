SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    cp.cp_catalog_number,
    cp.cp_type,
    cp.cp_catalog_page_number,
    d_ret.d_date AS return_date,
    d_start.d_date AS catalog_start_date,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    COUNT(*) AS return_count,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(wr.wr_return_amt) DESC) AS rank_within_store
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN catalog_page cp
    ON cp.cp_end_date_sk = d_ret.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    cp.cp_catalog_number,
    cp.cp_type,
    cp.cp_catalog_page_number,
    d_ret.d_date,
    d_start.d_date
ORDER BY total_return_amount DESC
LIMIT 50
