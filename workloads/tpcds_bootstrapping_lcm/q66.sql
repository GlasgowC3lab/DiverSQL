SELECT
    dr_return.d_year AS return_year,
    dr_return.d_month_seq AS return_month,
    c_ref.c_birth_country AS customer_birth_country,
    c_ret.c_first_name AS returning_customer_first_name,
    s.s_state AS store_state,
    ws_open.web_country AS website_country,
    ws_close.web_city AS website_close_city,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(CASE WHEN wr.wr_return_quantity % 2 = 0 THEN 1 ELSE 0 END) AS even_quantity_returns,
    SUM(CASE WHEN dr_return.d_weekend = 'Y' THEN wr.wr_return_amt ELSE 0 END) AS weekend_return_amount,
    AVG(ABS(wr.wr_returned_date_sk - ws_open.web_open_date_sk)) AS avg_return_open_date_sk_diff
FROM web_returns wr
JOIN date_dim dr_return
    ON wr.wr_returned_date_sk = dr_return.d_date_sk
JOIN customer c_ref
    ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer c_ret
    ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
JOIN store s
    ON s.s_closed_date_sk = dr_return.d_date_sk
JOIN web_site ws_open
    ON ws_open.web_open_date_sk = dr_return.d_date_sk
JOIN web_site ws_close
    ON ws_close.web_close_date_sk = dr_return.d_date_sk
GROUP BY
    dr_return.d_year,
    dr_return.d_month_seq,
    c_ref.c_birth_country,
    c_ret.c_first_name,
    s.s_state,
    ws_open.web_country,
    ws_close.web_city
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
