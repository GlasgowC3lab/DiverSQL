WITH aggregated AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        cc.cc_call_center_id,
        cc.cc_name AS call_center_name,
        cc.cc_city AS call_center_city,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers,
        AVG(c.c_birth_year) AS avg_birth_year,
        MIN(d_c_first_sales.d_date) AS earliest_customer_sales,
        MAX(d_c_first_shipto.d_date) AS latest_customer_shipto,
        DATE_DIFF('day', d_store_closed.d_date, d_cc_open.d_date) AS store_closed_to_cc_open_days
    FROM store s
    INNER JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    INNER JOIN call_center cc
        ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
    INNER JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    INNER JOIN customer c
        ON c.c_first_sales_date_sk = d_cc_open.d_date_sk
    INNER JOIN date_dim d_c_first_sales
        ON c.c_first_sales_date_sk = d_c_first_sales.d_date_sk
    INNER JOIN date_dim d_c_first_shipto
        ON c.c_first_shipto_date_sk = d_c_first_shipto.d_date_sk
    WHERE d_store_closed.d_year = 2020
      AND d_cc_open.d_year = 2019
      AND s.s_state = 'CA'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_city,
        d_store_closed.d_date,
        d_cc_open.d_date
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.s_city,
    a.cc_call_center_id,
    a.call_center_name,
    a.call_center_city,
    a.unique_customers,
    a.avg_birth_year,
    a.earliest_customer_sales,
    a.latest_customer_shipto,
    a.store_closed_to_cc_open_days,
    ROW_NUMBER() OVER (ORDER BY a.unique_customers DESC) AS sales_rank
FROM aggregated a
ORDER BY a.unique_customers DESC
LIMIT 100
