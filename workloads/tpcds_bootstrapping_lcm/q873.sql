SELECT
    c_ref.c_customer_id,
    c_ref.c_first_name,
    c_ref.c_last_name,
    c_ret.c_customer_id AS returning_customer_id,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    s.s_store_name,
    s.s_city AS store_city,
    ws.web_name,
    ws.web_city AS website_city,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    AVG(wr.wr_return_quantity) AS avg_quantity,
    MIN(d_ship.d_date) AS first_shipto_date,
    MAX(d_ship.d_date) AS last_shipto_date
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN customer c_ref
    ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer c_ret
    ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
JOIN date_dim d_ship
    ON c_ref.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year BETWEEN 2015 AND 2020
  AND s.s_state = 'CA'
  AND ws.web_state = 'CA'
GROUP BY
    c_ref.c_customer_id,
    c_ref.c_first_name,
    c_ref.c_last_name,
    c_ret.c_customer_id,
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_store_name,
    s.s_city,
    ws.web_name,
    ws.web_city
ORDER BY total_net_loss DESC
LIMIT 100
