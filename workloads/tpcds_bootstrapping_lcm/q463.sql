SELECT
    ws.web_name,
    s.s_store_name,
    rd.d_year AS return_year,
    rd.d_month_seq AS return_month,
    cr.c_birth_country,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    COUNT(*) FILTER (WHERE ws.web_gmt_offset > 0) AS ws_positive_gmt,
    MIN(rd.d_date) AS first_return_date,
    MAX(rd.d_date) AS last_return_date,
    MIN(fs.d_year) AS first_ship_year,
    MAX(fs.d_year) AS last_ship_year,
    MIN(fsales.d_year) AS first_sales_year,
    MAX(fsales.d_year) AS last_sales_year,
    rd.d_date AS store_closed_date
FROM web_returns wr
JOIN date_dim rd
    ON wr.wr_returned_date_sk = rd.d_date_sk
JOIN customer cr
    ON wr.wr_returning_customer_sk = cr.c_customer_sk
JOIN customer cf
    ON wr.wr_refunded_customer_sk = cf.c_customer_sk
JOIN store s
    ON s.s_closed_date_sk = rd.d_date_sk
JOIN web_site ws
    ON TRUE
JOIN date_dim wso
    ON ws.web_open_date_sk = wso.d_date_sk
JOIN date_dim wsc
    ON ws.web_close_date_sk = wsc.d_date_sk
JOIN date_dim fs
    ON cr.c_first_shipto_date_sk = fs.d_date_sk
JOIN date_dim fsales
    ON cr.c_first_sales_date_sk = fsales.d_date_sk
WHERE rd.d_year BETWEEN 2015 AND 2020
  AND ws.web_country = 'United States'
GROUP BY
    ws.web_name,
    s.s_store_name,
    rd.d_year,
    rd.d_month_seq,
    cr.c_birth_country,
    rd.d_date
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
