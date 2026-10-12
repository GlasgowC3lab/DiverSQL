SELECT
    dr.d_year AS return_year,
    dr.d_quarter_seq AS return_quarter,
    dc.d_month_seq AS page_creation_month,
    da.d_day_name AS page_access_day,
    s.s_state,
    r.r_reason_desc,
    COUNT(DISTINCT wr.wr_order_number) AS orders_returned,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_fee) AS total_fee,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    SUM(CASE WHEN wr.wr_return_tax > 0 THEN 1 ELSE 0 END) AS tax_return_count,
    SUM(wr.wr_net_loss) AS total_net_loss
FROM web_returns wr
JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim dc ON wp.wp_creation_date_sk = dc.d_date_sk
JOIN date_dim da ON wp.wp_access_date_sk = da.d_date_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN store s ON s.s_closed_date_sk = dr.d_date_sk
GROUP BY
    dr.d_year,
    dr.d_quarter_seq,
    dc.d_month_seq,
    da.d_day_name,
    s.s_state,
    r.r_reason_desc
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
