SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    ca_returning.ca_state AS returning_state,
    ca_refunded.ca_state AS refunded_state,
    d_return.d_year,
    d_return.d_month_seq,
    CASE
        WHEN d_return.d_month_seq BETWEEN 1 AND 6 THEN 'H1'
        ELSE 'H2'
    END AS half_year,
    wp.wp_type,
    d_creation.d_year AS creation_year,
    d_access.d_year AS access_year,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_return_tax) AS total_return_tax,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(CASE WHEN wr.wr_return_amt > 500 THEN wr.wr_return_amt ELSE 0 END) AS high_value_return_sum,
    COUNT(*) FILTER (WHERE wr.wr_return_amt > 500) AS high_value_return_count,
    SUM(wr.wr_fee) / NULLIF(SUM(wr.wr_return_amt), 0) AS fee_to_return_ratio,
    MIN(d_return.d_date) AS first_return_date,
    MAX(d_return.d_date) AS last_return_date
FROM web_returns wr
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN customer_address ca_refunded
    ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
    ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_return.d_year BETWEEN 2015 AND 2020
  AND s.s_state IS NOT NULL
GROUP BY
    s.s_store_id,
    s.s_city,
    s.s_state,
    ca_returning.ca_state,
    ca_refunded.ca_state,
    d_return.d_year,
    d_return.d_month_seq,
    CASE
        WHEN d_return.d_month_seq BETWEEN 1 AND 6 THEN 'H1'
        ELSE 'H2'
    END,
    wp.wp_type,
    d_creation.d_year,
    d_access.d_year
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
