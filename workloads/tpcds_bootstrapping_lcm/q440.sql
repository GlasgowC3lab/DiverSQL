WITH sales_agg AS (
    SELECT
        c.cc_call_center_id,
        c.cc_name,
        c.cc_city AS cc_city,
        s.s_store_id,
        s.s_store_name,
        s.s_city AS store_city,
        d_sold.d_year AS sold_year,
        d_ship.d_year AS ship_year,
        ca_bill.ca_city AS bill_city,
        ca_ship.ca_city AS ship_city,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_quantity) AS avg_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        SUM(ws.ws_coupon_amt) AS total_coupons,
        CASE 
            WHEN SUM(ws.ws_ext_sales_price) = 0 THEN 0 
            ELSE SUM(ws.ws_net_profit) / SUM(ws.ws_ext_sales_price) 
        END AS profit_margin
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
    JOIN call_center c ON c.cc_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2003
      AND s.s_state = 'CA'
      AND c.cc_state = 'CA'
    GROUP BY
        c.cc_call_center_id,
        c.cc_name,
        c.cc_city,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d_sold.d_year,
        d_ship.d_year,
        ca_bill.ca_city,
        ca_ship.ca_city
    HAVING SUM(ws.ws_ext_sales_price) > 50000
)
SELECT
    cc_call_center_id,
    cc_name,
    cc_city,
    s_store_id,
    s_store_name,
    store_city,
    sold_year,
    ship_year,
    bill_city,
    ship_city,
    total_sales,
    total_profit,
    avg_quantity,
    distinct_orders,
    total_coupons,
    profit_margin,
    ROW_NUMBER() OVER (PARTITION BY cc_call_center_id ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 50
