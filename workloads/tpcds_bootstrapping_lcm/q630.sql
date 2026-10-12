SELECT
    d_sold.d_year AS sale_year,
    s.s_store_name,
    ws.web_name,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(cs.cs_net_paid) - SUM(wr.wr_return_amt) AS net_sales_minus_returns,
    AVG(cs.cs_net_profit) AS avg_sales_profit,
    AVG(wr.wr_net_loss) AS avg_return_loss,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d_sold.d_date_sk
CROSS JOIN date_dim d_store
JOIN store s ON s.s_closed_date_sk = d_store.d_date_sk
CROSS JOIN date_dim d_open
JOIN web_site ws ON ws.web_open_date_sk = d_open.d_date_sk
JOIN date_dim d_close ON ws.web_close_date_sk = d_close.d_date_sk
WHERE d_sold.d_year = 2022
GROUP BY
    d_sold.d_year,
    s.s_store_name,
    ws.web_name
ORDER BY net_sales_minus_returns DESC
LIMIT 100
