SELECT
    cc.cc_name,
    cc.cc_city,
    s.s_store_name,
    s.s_state,
    d_cc_closed.d_year AS cc_closed_year,
    d_cc_open.d_year AS cc_open_year,
    d_store_closed.d_year AS store_closed_year,
    d_returned.d_year AS return_year,
    d_sold.d_year AS sold_year,
    d_ship.d_year AS ship_year,
    CASE WHEN d_sold.d_moy BETWEEN 1 AND 6 THEN 'H1' ELSE 'H2' END AS sold_half_year,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_returns,
    SUM(CASE WHEN cs.cs_quantity > 10 THEN cs.cs_net_paid ELSE 0 END) AS high_quantity_sales,
    SUM(CASE WHEN wr.wr_return_quantity > 5 THEN wr.wr_return_amt ELSE 0 END) AS high_quantity_returns
FROM call_center cc
JOIN catalog_sales cs
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
CROSS JOIN web_returns wr
JOIN date_dim d_returned
    ON wr.wr_returned_date_sk = d_returned.d_date_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
GROUP BY
    cc.cc_name,
    cc.cc_city,
    s.s_store_name,
    s.s_state,
    d_cc_closed.d_year,
    d_cc_open.d_year,
    d_store_closed.d_year,
    d_returned.d_year,
    d_sold.d_year,
    d_ship.d_year,
    CASE WHEN d_sold.d_moy BETWEEN 1 AND 6 THEN 'H1' ELSE 'H2' END
LIMIT 100
