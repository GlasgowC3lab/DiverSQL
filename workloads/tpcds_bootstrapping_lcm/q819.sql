SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    sold_date.d_year,
    sold_date.d_month_seq AS month_seq,
    CASE WHEN s.s_tax_percentage > 5.00 THEN 'HighTax' ELSE 'LowTax' END AS tax_category,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_amount,
    SUM(ws.ws_ext_sales_price) AS total_ext_sales_price,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    COUNT(DISTINCT c_bill.c_customer_id) AS distinct_bill_customers,
    COUNT(DISTINCT c_ship.c_customer_id) AS distinct_ship_customers,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    SUM(CASE WHEN wp.wp_type = 'Home' THEN 1 ELSE 0 END) AS home_page_visits,
    SUM(CASE WHEN wp.wp_type = 'Product' THEN 1 ELSE 0 END) AS product_page_visits,
    MIN(first_sales_date.d_date) AS earliest_customer_first_sales,
    MAX(last_review_date.d_date) AS latest_customer_review,
    MAX(store_closed_date.d_date) AS store_closed_date,
    (SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0)) AS profit_margin
FROM web_sales ws
JOIN date_dim sold_date ON ws.ws_sold_date_sk = sold_date.d_date_sk
JOIN date_dim ship_date ON ws.ws_ship_date_sk = ship_date.d_date_sk
JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim wp_creation_date ON wp.wp_creation_date_sk = wp_creation_date.d_date_sk
JOIN date_dim wp_access_date ON wp.wp_access_date_sk = wp_access_date.d_date_sk
JOIN customer c_page ON wp.wp_customer_sk = c_page.c_customer_sk
JOIN date_dim first_shipto_date ON c_page.c_first_shipto_date_sk = first_shipto_date.d_date_sk
JOIN date_dim first_sales_date ON c_page.c_first_sales_date_sk = first_sales_date.d_date_sk
JOIN date_dim last_review_date ON c_page.c_last_review_date = last_review_date.d_date_sk
JOIN date_dim store_closed_date ON ws.ws_sold_date_sk = store_closed_date.d_date_sk
JOIN store s ON s.s_closed_date_sk = store_closed_date.d_date_sk
WHERE sold_date.d_year = 2022
  AND s.s_state = 'CA'
  AND wp.wp_type IS NOT NULL
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    sold_date.d_year,
    sold_date.d_month_seq,
    CASE WHEN s.s_tax_percentage > 5.00 THEN 'HighTax' ELSE 'LowTax' END
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 10
