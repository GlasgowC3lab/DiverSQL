WITH
    ws_agg AS (
        SELECT
            ws.ws_ship_mode_sk,
            ws.ws_warehouse_sk,
            ws.ws_sold_date_sk,
            ws.ws_sold_time_sk,
            SUM(ws.ws_ext_sales_price) AS total_sales,
            SUM(ws.ws_quantity) AS total_qty,
            COUNT(*) AS order_cnt
        FROM tpcds.web_sales ws
        WHERE ws.ws_sold_date_sk IS NOT NULL
        GROUP BY ws.ws_ship_mode_sk, ws.ws_warehouse_sk, ws.ws_sold_date_sk, ws.ws_sold_time_sk
    ),
    cust_purchase_2022 AS (
        SELECT DISTINCT ws.ws_bill_customer_sk AS cust_sk
        FROM tpcds.web_sales ws
        JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2022
    ),
    cust_purchase_2023 AS (
        SELECT DISTINCT ws.ws_bill_customer_sk AS cust_sk
        FROM tpcds.web_sales ws
        JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2023
    ),
    new_customers AS (
        SELECT cust_sk FROM cust_purchase_2022
        EXCEPT
        SELECT cust_sk FROM cust_purchase_2023
    ),
    base_sales AS (
        SELECT ws.*, t.t_hour, t.t_time_sk
        FROM tpcds.web_sales ws
        RIGHT OUTER JOIN tpcds.time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    )
SELECT
    d.d_year,
    bs.t_hour,
    sm.sm_type,
    w.w_warehouse_name,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    SUM(COALESCE(a.total_sales, 0)) AS sum_sales,
    AVG(COALESCE(a.total_sales, 0)) AS avg_sales,
    MIN(COALESCE(a.total_sales, 0)) AS min_sales,
    MAX(COALESCE(a.total_sales, 0)) AS max_sales
FROM base_sales bs
FULL OUTER JOIN tpcds.ship_mode sm ON sm.sm_ship_mode_sk = bs.ws_ship_mode_sk
LEFT JOIN ws_agg a ON a.ws_ship_mode_sk = bs.ws_ship_mode_sk
    AND a.ws_warehouse_sk = bs.ws_warehouse_sk
    AND a.ws_sold_date_sk = bs.ws_sold_date_sk
    AND a.ws_sold_time_sk = bs.ws_sold_time_sk
LEFT JOIN tpcds.date_dim d ON bs.ws_sold_date_sk = d.d_date_sk
LEFT JOIN tpcds.warehouse w ON bs.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN tpcds.web_page wp ON bs.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN tpcds.web_site site ON bs.ws_web_site_sk = site.web_site_sk
LEFT JOIN tpcds.customer c ON bs.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN tpcds.customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE d.d_year BETWEEN 2021 AND 2022
  AND sm.sm_carrier = 'UPS'
  AND w.w_state = 'CA'
  AND bs.t_hour BETWEEN 9 AND 17
  AND ca.ca_country = 'United States'
  AND site.web_country = 'United States'
  AND c.c_preferred_cust_flag = 'Y'
  AND c.c_customer_sk IN (SELECT cust_sk FROM new_customers)
GROUP BY d.d_year, bs.t_hour, sm.sm_type, w.w_warehouse_name
HAVING SUM(COALESCE(a.total_sales, 0)) > 100000
ORDER BY sum_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
