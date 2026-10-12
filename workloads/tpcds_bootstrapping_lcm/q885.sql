SELECT
    s.s_state,
    s.s_city,
    cp.cp_type,
    d_ret.d_year,
    d_ret.d_month_seq,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    AVG(wr.wr_return_quantity) AS avg_quantity,
    SUM(CASE WHEN wr.wr_fee > 0 THEN wr.wr_fee ELSE 0 END) AS total_fee,
    SUM(wp.wp_image_count) AS total_image_count
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_create
    ON wp.wp_creation_date_sk = d_create.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN catalog_page cp
    ON cp.cp_end_date_sk = d_ret.d_date_sk
GROUP BY
    s.s_state,
    s.s_city,
    cp.cp_type,
    d_ret.d_year,
    d_ret.d_month_seq
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
