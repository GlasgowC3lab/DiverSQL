SELECT
    cc.cc_call_center_id,
    cc.cc_name AS call_center_name,
    cc.cc_city AS call_center_city,
    s.s_store_id,
    s.s_store_name,
    s.s_city AS store_city,
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    d_sold.d_year,
    d_sold.d_month_seq,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_amount,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ship.d_date_sk
   AND cc.cc_open_date_sk = d_sold.d_date_sk
WHERE i.i_category = 'Sports'
  AND s.s_state = 'CA'
  AND d_sold.d_year = 2022
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    d_sold.d_year,
    d_sold.d_month_seq
ORDER BY total_sales_amount DESC
LIMIT 50
