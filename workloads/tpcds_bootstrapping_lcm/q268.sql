SELECT
    d.d_year AS return_year,
    d.d_month_seq AS return_month,
    d.d_date AS return_date,
    r.r_reason_desc AS return_reason,
    s.s_store_name,
    s.s_state,
    s.s_floor_space,
    wp.wp_type,
    wp.wp_url,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_fee) AS avg_fee,
    SUM(wr.wr_return_quantity) AS total_return_quantity,
    COUNT(*) AS total_returns,
    DATE_DIFF('day', d_creation.d_date, d.d_date) AS days_since_page_creation,
    DATE_DIFF('day', d_access.d_date, d.d_date) AS days_since_last_access,
    CASE
        WHEN s.s_floor_space > 50000 THEN 'Large Store'
        WHEN s.s_floor_space > 20000 THEN 'Medium Store'
        ELSE 'Small Store'
    END AS store_size_category
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d.d_year >= 2000
  AND s.s_state IS NOT NULL
GROUP BY
    d.d_year,
    d.d_month_seq,
    d.d_date,
    r.r_reason_desc,
    s.s_store_name,
    s.s_state,
    s.s_floor_space,
    wp.wp_type,
    wp.wp_url,
    d_creation.d_date,
    d_access.d_date
ORDER BY total_return_amount DESC
LIMIT 100
