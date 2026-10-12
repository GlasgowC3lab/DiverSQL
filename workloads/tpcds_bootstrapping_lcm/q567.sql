SELECT
    cp.cp_type,
    cp.cp_department,
    s.s_state,
    CASE
        WHEN d_wr_ret.d_month_seq % 2 = 0 THEN 'EvenMonth'
        ELSE 'OddMonth'
    END AS month_parity,
    date_diff('day', d_cp_start.d_date, d_wr_ret.d_date) AS catalog_page_duration_days,
    (ca_returning.ca_city || '-' || ca_refunded.ca_city) AS address_pair,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_tax) AS avg_return_tax,
    SUM(wr.wr_fee) AS total_fees,
    COUNT(CASE WHEN ca_returning.ca_country = 'United States' THEN 1 END) AS us_returning_address_count,
    COUNT(CASE WHEN ca_refunded.ca_country = 'United States' THEN 1 END) AS us_refunded_address_count
FROM web_returns wr
JOIN date_dim d_wr_ret
    ON wr.wr_returned_date_sk = d_wr_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_wr_ret.d_date_sk
JOIN catalog_page cp
    ON cp.cp_end_date_sk = d_wr_ret.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN customer_address ca_returning
    ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
JOIN customer_address ca_refunded
    ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
WHERE d_wr_ret.d_year = 2022
GROUP BY
    cp.cp_type,
    cp.cp_department,
    s.s_state,
    CASE
        WHEN d_wr_ret.d_month_seq % 2 = 0 THEN 'EvenMonth'
        ELSE 'OddMonth'
    END,
    date_diff('day', d_cp_start.d_date, d_wr_ret.d_date),
    (ca_returning.ca_city || '-' || ca_refunded.ca_city)
HAVING COUNT(*) > 10
ORDER BY total_return_amount DESC
LIMIT 100
