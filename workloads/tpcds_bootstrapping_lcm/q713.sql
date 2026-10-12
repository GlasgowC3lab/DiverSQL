SELECT
    cp.cp_department,
    cp.cp_type,
    d_end.d_year,
    d_sold.d_month_seq,
    d_ship.d_week_seq,
    s.s_state,
    s.s_city,
    s.s_market_desc,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(DISTINCT wr.wr_return_quantity) AS distinct_return_items
FROM catalog_page cp
JOIN catalog_sales cs
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_end.d_date_sk
GROUP BY
    cp.cp_department,
    cp.cp_type,
    d_end.d_year,
    d_sold.d_month_seq,
    d_ship.d_week_seq,
    s.s_state,
    s.s_city,
    s.s_market_desc
ORDER BY total_net_paid DESC
LIMIT 100
