SELECT
    s.s_store_name,
    s.s_city,
    r.r_reason_desc,
    d_return.d_year AS return_year,
    d_ship.d_month_seq AS ship_month_seq,
    COUNT(DISTINCT cs.cs_order_number) AS total_sales_orders,
    SUM(cs.cs_net_paid) AS total_sales_amount,
    SUM(wr.wr_return_amt) AS total_return_amount,
    (SUM(cs.cs_net_paid) - SUM(wr.wr_return_amt)) AS net_sales_vs_returns,
    AVG(cs.cs_quantity) AS avg_quantity_sold,
    AVG(wr.wr_return_quantity) AS avg_quantity_returned
FROM web_returns wr
JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN catalog_sales cs ON cs.cs_sold_date_sk = d_return.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_return.d_date_sk
WHERE d_return.d_year BETWEEN 1998 AND 2000
GROUP BY
    s.s_store_name,
    s.s_city,
    r.r_reason_desc,
    d_return.d_year,
    d_ship.d_month_seq
ORDER BY net_sales_vs_returns DESC
LIMIT 100
