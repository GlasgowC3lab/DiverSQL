SELECT
    s.s_store_id,
    s.s_city,
    cp.cp_department,
    wp.wp_type,
    d_ret.d_year,
    CASE
        WHEN sr.sr_return_quantity >= 5 THEN 'Bulk'
        ELSE 'Single'
    END AS return_quantity_bucket,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    SUM(sr.sr_return_tax) AS total_return_tax,
    COUNT(*) FILTER (WHERE sr.sr_fee > 0) AS fee_transactions,
    AVG(sr.sr_fee) FILTER (WHERE sr.sr_fee > 0) AS avg_fee,
    MAX(d_access.d_current_month) AS latest_access_month
FROM store_returns sr
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN catalog_page cp
    ON cp.cp_end_date_sk = d_ret.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ret.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_ret.d_year = 2021
  AND s.s_state = 'TX'
  AND d_closed.d_current_year = '2020'
GROUP BY
    s.s_store_id,
    s.s_city,
    cp.cp_department,
    wp.wp_type,
    d_ret.d_year,
    CASE
        WHEN sr.sr_return_quantity >= 5 THEN 'Bulk'
        ELSE 'Single'
    END
ORDER BY total_net_loss DESC
LIMIT 100
