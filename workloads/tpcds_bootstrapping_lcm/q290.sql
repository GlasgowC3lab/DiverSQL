SELECT
    d_ret.d_year AS return_year,
    s.s_state,
    CASE WHEN c.c_birth_month <= 6 THEN 'H1' ELSE 'H2' END AS birth_half,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
    AVG(wr.wr_return_quantity) AS avg_web_return_qty,
    SUM(CASE WHEN cr.cr_return_amount > 100 THEN cr.cr_return_amount ELSE 0 END) AS high_value_catalog_returns,
    SUM(CASE WHEN wr.wr_return_amt > 100 THEN wr.wr_return_amt ELSE 0 END) AS high_value_web_returns,
    COUNT(*) AS total_returns
FROM catalog_returns cr
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN customer c2 ON wr.wr_refunded_customer_sk = c2.c_customer_sk
JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_cust_first_ship ON c.c_first_shipto_date_sk = d_cust_first_ship.d_date_sk
JOIN date_dim d_cust_first_sales ON c.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
GROUP BY
    d_ret.d_year,
    s.s_state,
    CASE WHEN c.c_birth_month <= 6 THEN 'H1' ELSE 'H2' END
HAVING
    SUM(cr.cr_net_loss) > 0
ORDER BY total_catalog_net_loss DESC
LIMIT 100
