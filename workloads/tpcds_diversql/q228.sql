WITH ca_ca AS (
       SELECT ca_address_sk
       FROM customer_address
       WHERE ca_state = 'CA'
   ),
   ca_zip AS (
       SELECT ca_address_sk
       FROM customer_address
       WHERE ca_zip LIKE '9%'
   )
SELECT
    d1.d_year,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) > SUM(ws.ws_ext_sales_price) THEN 'Store Higher'
        ELSE 'Web Higher'
    END AS sales_comparison,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
    COUNT(DISTINCT ws.ws_order_number) AS web_transactions
FROM
    store_sales ss
    JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d1.d_date_sk
    JOIN date_dim d2 ON ws.ws_ship_date_sk = d2.d_date_sk
    JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d2.d_date_sk
WHERE
    ca.ca_address_sk IN (
        SELECT ca_address_sk FROM ca_ca
        INTERSECT
        SELECT ca_address_sk FROM ca_zip
    )
    AND NOT EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_order_number = ss.ss_ticket_number
    )
GROUP BY
    d1.d_year
ORDER BY
    total_store_sales DESC
LIMIT 100
