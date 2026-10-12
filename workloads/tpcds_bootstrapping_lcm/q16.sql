SELECT
    cd_bill.cd_gender AS bill_gender,
    cd_bill.cd_marital_status AS bill_marital_status,
    cd_ship.cd_gender AS ship_gender,
    wp.wp_type,
    wp.wp_url,
    st.s_state,
    st.s_city,
    d_sold.d_year,
    d_sold.d_month_seq,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_coupon_amt) AS avg_coupon_amt,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM web_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd_bill
  ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
  ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation
  ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
  ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN store st
  ON st.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_store_closed
  ON st.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2002
  AND st.s_state = 'WA'
GROUP BY
    cd_bill.cd_gender,
    cd_bill.cd_marital_status,
    cd_ship.cd_gender,
    wp.wp_type,
    wp.wp_url,
    st.s_state,
    st.s_city,
    d_sold.d_year,
    d_sold.d_month_seq
ORDER BY total_profit DESC
LIMIT 100
