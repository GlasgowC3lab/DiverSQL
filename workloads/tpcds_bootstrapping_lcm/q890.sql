SELECT
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    ws.web_name,
    ws.web_city,
    ws.web_state,
    d.d_year,
    d.d_month_seq,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_returns,
    (SUM(cs.cs_net_paid) - COALESCE(SUM(wr.wr_return_amt), 0)) AS net_revenue,
    AVG(date_diff('day', d.d_date, d_ship.d_date)) AS avg_ship_lag_days,
    SUM(cs.cs_ext_tax) AS total_tax,
    SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
    SUM(cs.cs_coupon_amt) AS total_coupon_amount,
    SUM(cs.cs_ext_wholesale_cost) AS total_wholesale_cost
FROM catalog_sales cs
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
JOIN date_dim d_web_close
    ON ws.web_close_date_sk = d_web_close.d_date_sk
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    ws.web_name,
    ws.web_city,
    ws.web_state,
    d.d_year,
    d.d_month_seq
ORDER BY net_revenue DESC
LIMIT 100
