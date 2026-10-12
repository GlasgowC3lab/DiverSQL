SELECT
    s.s_store_id,
    s.s_store_name,
    ws.web_site_id,
    ws.web_name,
    dd_sold.d_year AS sold_year,
    dd_ship.d_year AS ship_year,
    dd_web_close.d_year AS web_close_year,
    SUM(cs.cs_ext_sales_price) AS total_sales_price,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_return_loss,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_return_orders,
    (SUM(cs.cs_ext_sales_price) - COALESCE(SUM(wr.wr_return_amt), 0)) AS net_sales_after_returns
FROM catalog_sales cs
JOIN date_dim dd_sold
    ON cs.cs_sold_date_sk = dd_sold.d_date_sk
JOIN date_dim dd_ship
    ON cs.cs_ship_date_sk = dd_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dd_sold.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = dd_sold.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = dd_sold.d_date_sk
JOIN date_dim dd_web_close
    ON ws.web_close_date_sk = dd_web_close.d_date_sk
WHERE dd_sold.d_year >= 2000
GROUP BY
    s.s_store_id,
    s.s_store_name,
    ws.web_site_id,
    ws.web_name,
    dd_sold.d_year,
    dd_ship.d_year,
    dd_web_close.d_year
ORDER BY total_net_paid DESC
LIMIT 100
