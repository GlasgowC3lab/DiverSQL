SELECT
    ca_refunded.ca_city AS refunded_city,
    ca_refunded.ca_state AS refunded_state,
    ca_returning.ca_country AS returning_country,
    ca_returning.ca_zip AS returning_zip,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_day_name,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    s.s_number_employees,
    ws_open.web_name AS site_open_name,
    ws_open.web_city AS site_open_city,
    ws_open.web_state AS site_open_state,
    ws_close.web_name AS site_close_name,
    ws_close.web_city AS site_close_city,
    ws_close.web_state AS site_close_state,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_fee) AS avg_fee,
    MIN(wr.wr_return_quantity) AS min_quantity,
    MAX(wr.wr_return_quantity) AS max_quantity
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN customer_address ca_refunded
    ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
    ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_site ws_open
    ON ws_open.web_open_date_sk = d_ret.d_date_sk
JOIN web_site ws_close
    ON ws_close.web_close_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year BETWEEN 2000 AND 2002
GROUP BY
    ca_refunded.ca_city,
    ca_refunded.ca_state,
    ca_returning.ca_country,
    ca_returning.ca_zip,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_day_name,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_number_employees,
    ws_open.web_name,
    ws_open.web_city,
    ws_open.web_state,
    ws_close.web_name,
    ws_close.web_city,
    ws_close.web_state
ORDER BY total_net_loss DESC
LIMIT 100
