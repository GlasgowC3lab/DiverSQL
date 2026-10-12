SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    s.s_state,
    s.s_city,
    c_refunded.c_birth_country,
    c_refunded.c_first_name,
    c_refunded.c_last_name,
    c_returning.c_email_address,
    COUNT(*) AS return_cnt,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    MAX(wp.wp_url) AS sample_url,
    MIN(d_creation.d_date) AS earliest_creation_date,
    MAX(d_access.d_date) AS latest_access_date,
    MIN(d_shipto.d_date) AS shipto_date,
    MIN(d_sales.d_date) AS first_sales_date
FROM web_returns wr
JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN customer c_refunded ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer c_returning ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN date_dim d_shipto ON c_refunded.c_first_shipto_date_sk = d_shipto.d_date_sk
JOIN date_dim d_sales ON c_refunded.c_first_sales_date_sk = d_sales.d_date_sk
WHERE d_ret.d_year BETWEEN 2000 AND 2005
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_state,
    s.s_city,
    c_refunded.c_birth_country,
    c_refunded.c_first_name,
    c_refunded.c_last_name,
    c_returning.c_email_address
ORDER BY total_net_loss DESC
LIMIT 100
