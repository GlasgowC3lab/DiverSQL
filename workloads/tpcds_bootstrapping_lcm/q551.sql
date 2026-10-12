SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_id,
    s.s_city,
    ws.web_name,
    ws.web_city,
    cp.cp_catalog_page_id,
    cp.cp_type,
    cp.cp_description,
    d_cp_start.d_date AS catalog_start_date,
    d_cp_end.d_date   AS catalog_end_date,
    d_cust_sales.d_date      AS first_sales_date,
    d_cust_shipto.d_date     AS first_shipto_date,
    d_store_closed.d_date    AS store_closed_date,
    d_ws_open.d_date         AS website_open_date,
    d_ws_close.d_date        AS website_close_date,
    DATE_DIFF('day', d_cp_start.d_date, d_cp_end.d_date)   AS catalog_page_duration_days,
    DATE_DIFF('day', d_ws_open.d_date, d_ws_close.d_date) AS website_lifespan_days,
    CASE
        WHEN d_cust_sales.d_date BETWEEN d_cp_start.d_date AND d_cp_end.d_date THEN 1
        ELSE 0
    END AS catalog_active_at_first_sales,
    CASE
        WHEN d_ws_open.d_date <= d_cp_end.d_date
             AND d_ws_close.d_date >= d_cp_start.d_date THEN 1
        ELSE 0
    END AS website_overlaps_catalog,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY d_cust_sales.d_date) AS sales_event_rank
FROM
    catalog_page cp
    JOIN date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN customer c
        ON c.c_first_sales_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cust_sales
        ON c.c_first_sales_date_sk = d_cust_sales.d_date_sk
    JOIN date_dim d_cust_shipto
        ON c.c_first_shipto_date_sk = d_cust_shipto.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_cust_shipto.d_date_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_ws_open
        ON ws.web_open_date_sk = d_ws_open.d_date_sk
    JOIN date_dim d_ws_close
        ON ws.web_close_date_sk = d_ws_close.d_date_sk
WHERE
    cp.cp_type = 'PROMO'
    AND s.s_state = 'CA'
    AND ws.web_state = 'CA'
    AND d_cp_start.d_year = d_cust_sales.d_year
ORDER BY
    c.c_customer_id,
    d_cust_sales.d_date
