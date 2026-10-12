SELECT
    (d_cc_closed.d_year * 100 + d_cc_closed.d_month_seq) AS year_month_key,
    cc.cc_division_name,
    s.s_state,
    CASE WHEN d_cc_closed.d_quarter_name = 'Q1' THEN 'FirstQuarter' ELSE 'OtherQuarter' END AS quarter_category,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(s.s_floor_space) AS total_floor_space,
    AVG(cp.cp_catalog_page_number) AS avg_page_number,
    SUM(cc.cc_sq_ft) AS total_cc_sqft,
    COUNT(cp.cp_catalog_page_id) AS total_pages,
    MAX(d_cust_sales.d_holiday) AS latest_sales_holiday
FROM call_center cc
INNER JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
INNER JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
INNER JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
INNER JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
INNER JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_cc_open.d_date_sk
INNER JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
INNER JOIN customer c
    ON c.c_first_shipto_date_sk = d_cc_closed.d_date_sk
INNER JOIN date_dim d_cust_shipto
    ON c.c_first_shipto_date_sk = d_cust_shipto.d_date_sk
INNER JOIN date_dim d_cust_sales
    ON c.c_first_sales_date_sk = d_cust_sales.d_date_sk
WHERE d_cc_closed.d_year BETWEEN 2000 AND 2020
GROUP BY
    (d_cc_closed.d_year * 100 + d_cc_closed.d_month_seq),
    cc.cc_division_name,
    s.s_state,
    CASE WHEN d_cc_closed.d_quarter_name = 'Q1' THEN 'FirstQuarter' ELSE 'OtherQuarter' END
HAVING COUNT(*) > 5
ORDER BY total_floor_space DESC
LIMIT 100
