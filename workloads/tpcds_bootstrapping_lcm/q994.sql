SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    s.s_store_name,
    d.d_year AS closed_year,
    d_open.d_year AS open_year,
    d_ship.d_year AS ship_year,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_net_loss) AS total_return_loss,
    SUM(cs.cs_ext_discount_amt) - SUM(wr.wr_fee) AS net_discount_minus_fee,
    AVG(cs.cs_quantity) AS avg_quantity,
    MIN(cs.cs_sales_price) AS min_sales_price,
    MAX(cs.cs_sales_price) AS max_sales_price
FROM date_dim d
JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
JOIN catalog_sales cs
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
    AND cs.cs_sold_date_sk = d.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    s.s_store_name,
    d.d_year,
    d_open.d_year,
    d_ship.d_year
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
