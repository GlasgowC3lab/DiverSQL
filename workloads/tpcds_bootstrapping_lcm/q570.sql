SELECT
    s.s_store_id,
    cc.cc_call_center_id,
    d_store_closed.d_year AS year,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS num_catalog_pages,
    SUM(CASE WHEN cp.cp_type = 'Online' THEN 1 ELSE 0 END) AS online_catalog_pages,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax_pct,
    AVG(s.s_tax_percentage) AS avg_store_tax_pct,
    SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_customers,
    AVG(c.c_birth_year) AS avg_birth_year,
    AVG(date_diff('day', d_c_first_ship.d_date, d_c_last_review.d_date)) AS avg_days_ship_to_review
FROM
    store s
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    CROSS JOIN call_center cc
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    CROSS JOIN catalog_page cp
    JOIN date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    CROSS JOIN customer c
    JOIN date_dim d_c_first_ship
        ON c.c_first_shipto_date_sk = d_c_first_ship.d_date_sk
    JOIN date_dim d_c_first_sales
        ON c.c_first_sales_date_sk = d_c_first_sales.d_date_sk
    JOIN date_dim d_c_last_review
        ON c.c_last_review_date = d_c_last_review.d_date_sk
WHERE
    d_store_closed.d_year = d_cc_closed.d_year
    AND d_store_closed.d_year = d_cc_open.d_year
    AND d_store_closed.d_year = d_cp_start.d_year
    AND d_store_closed.d_year = d_cp_end.d_year
    AND d_store_closed.d_year = d_c_first_ship.d_year
    AND d_store_closed.d_year = d_c_first_sales.d_year
    AND d_store_closed.d_year = d_c_last_review.d_year
GROUP BY
    ROLLUP (s.s_store_id, cc.cc_call_center_id, d_store_closed.d_year)
