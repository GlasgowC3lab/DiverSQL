SELECT
    d_returned.d_year AS return_year,
    d_returned.d_month_seq AS return_month,
    s.s_state AS store_state,
    CASE
        WHEN s.s_floor_space > 20000 THEN 'Very Large'
        WHEN s.s_floor_space > 10000 THEN 'Large'
        ELSE 'Small'
    END AS store_size_category,
    r.r_reason_desc AS reason,
    wp.wp_type AS page_type,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    AVG(wr.wr_net_loss) AS avg_net_loss,
    SUM(CASE WHEN wr.wr_return_quantity > 5 THEN wr.wr_return_amt ELSE 0 END) AS high_quantity_return_amount,
    SUM(CASE WHEN d_returned.d_weekend = 'Y' THEN wr.wr_return_amt ELSE 0 END) AS weekend_return_amount,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
FROM
    web_returns wr
JOIN date_dim d_returned
    ON wr.wr_returned_date_sk = d_returned.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d_returned.d_date_sk
WHERE
    d_returned.d_year BETWEEN 2015 AND 2020
    AND wp.wp_type IS NOT NULL
GROUP BY
    d_returned.d_year,
    d_returned.d_month_seq,
    s.s_state,
    CASE
        WHEN s.s_floor_space > 20000 THEN 'Very Large'
        WHEN s.s_floor_space > 10000 THEN 'Large'
        ELSE 'Small'
    END,
    r.r_reason_desc,
    wp.wp_type
HAVING
    SUM(wr.wr_return_amt) > 1000
ORDER BY
    d_returned.d_year,
    d_returned.d_month_seq,
    total_returns DESC
LIMIT 100
