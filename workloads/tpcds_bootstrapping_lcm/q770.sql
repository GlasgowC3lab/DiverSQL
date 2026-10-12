SELECT
    d_sales.d_year,
    d_sales.d_month_seq,
    s.s_division_name,
    s.s_state,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(wp.wp_char_count) AS avg_page_char_count,
    CASE
        WHEN COUNT(DISTINCT ss.ss_ticket_number) = 0 THEN 0
        ELSE CAST(COUNT(DISTINCT sr.sr_ticket_number) AS double) / COUNT(DISTINCT ss.ss_ticket_number)
    END AS return_rate,
    SUM(CASE WHEN sr.sr_return_amt > 0 THEN sr.sr_return_amt ELSE 0 END) AS total_positive_return_amt,
    MAX(d_closed.d_date) AS store_closed_date,
    MIN(d_access.d_year) AS access_year_of_page
FROM
    date_dim d_sales
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sales.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE
    d_sales.d_year = 2022
    AND s.s_state = 'CA'
GROUP BY
    d_sales.d_year,
    d_sales.d_month_seq,
    s.s_division_name,
    s.s_state
HAVING
    SUM(ss.ss_net_profit) > 0
ORDER BY
    total_net_profit DESC
LIMIT 100
