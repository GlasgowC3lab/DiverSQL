SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    d_cc_open.d_year AS cc_open_year,
    d_cc_closed.d_year AS cc_closed_year,
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month_seq,
    d_ship.d_year AS ship_year,
    d_ship.d_month_seq AS ship_month_seq,
    s.s_store_name,
    s.s_state,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    COUNT(DISTINCT wr.wr_order_number) AS return_order_count,
    (SUM(cs.cs_net_paid) - SUM(wr.wr_return_amt)) AS net_sales_after_returns
FROM call_center cc
JOIN catalog_sales cs
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_ship.d_date_sk
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    d_cc_open.d_year,
    d_cc_closed.d_year,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_year,
    d_ship.d_month_seq,
    s.s_store_name,
    s.s_state
ORDER BY net_sales_after_returns DESC
LIMIT 100
