SELECT
    cc.cc_division,
    s.s_state,
    i.i_category,
    (d_sold.d_year * 10 + d_sold.d_quarter_seq) AS year_quarter,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    COUNT(*) AS sales_transactions,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    CASE WHEN SUM(ws.ws_ext_sales_price) <> 0 THEN SUM(ws.ws_net_profit) / SUM(ws.ws_ext_sales_price) END AS profit_margin
FROM web_sales ws
INNER JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
INNER JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
INNER JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
INNER JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
INNER JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ship.d_date_sk
INNER JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2002
  AND d_cc_open.d_year >= 1995
  AND i.i_category IS NOT NULL
GROUP BY
    cc.cc_division,
    s.s_state,
    i.i_category,
    (d_sold.d_year * 10 + d_sold.d_quarter_seq)
HAVING SUM(ws.ws_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
