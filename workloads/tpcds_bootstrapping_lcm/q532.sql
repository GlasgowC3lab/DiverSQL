SELECT
    d_sales.d_year AS sales_year,
    s.s_division_name,
    ws.web_mkt_class,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    SUM(s.s_floor_space) AS total_store_floor_space,
    AVG(ws.web_tax_percentage) AS avg_site_tax_percentage,
    SUM(wp.wp_char_count) AS total_page_characters,
    COUNT(wp.wp_web_page_sk) AS total_web_pages,
    CASE
        WHEN d_sales.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d_sales.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d_sales.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS sales_quarter,
    MIN(d_page_creation.d_date) AS earliest_page_creation_date,
    MAX(d_page_access.d_date) AS latest_page_access_date
FROM customer c
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_ship
    ON c.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim d_page_creation
    ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
JOIN date_dim d_page_access
    ON wp.wp_access_date_sk = d_page_access.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store_close
    ON s.s_closed_date_sk = d_store_close.d_date_sk
CROSS JOIN web_site ws
JOIN date_dim d_site_open
    ON ws.web_open_date_sk = d_site_open.d_date_sk
LEFT JOIN date_dim d_site_close
    ON ws.web_close_date_sk = d_site_close.d_date_sk
WHERE d_sales.d_year >= 2000
GROUP BY
    d_sales.d_year,
    s.s_division_name,
    ws.web_mkt_class,
    CASE
        WHEN d_sales.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d_sales.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d_sales.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END
ORDER BY d_sales.d_year DESC, s.s_division_name
LIMIT 100
