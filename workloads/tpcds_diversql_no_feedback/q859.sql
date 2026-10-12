WITH sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk,
        d.d_year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        MIN(d.d_date) AS any_date,
        MIN(t.t_time) AS any_time,
        MIN(cc.cc_name) AS call_center_name,
        MIN(cp.cp_description) AS page_desc,
        MIN(c.c_first_name) AS cust_first,
        MIN(c.c_last_name) AS cust_last
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND t.t_am_pm = 'PM'
      AND cc.cc_employees > 50
      AND cp.cp_catalog_number IN (1, 6, 7)
      AND NOT EXISTS (
          SELECT 1
          FROM call_center cc2
          WHERE cc2.cc_state = cc.cc_state
            AND cc2.cc_call_center_sk <> cc.cc_call_center_sk
      )
    GROUP BY cs.cs_bill_customer_sk, d.d_year
)
SELECT
    sa.cust_first,
    sa.cust_last,
    sa.call_center_name,
    sa.page_desc,
    sa.any_date,
    sa.any_time,
    sa.total_sales,
    RANK() OVER (PARTITION BY sa.d_year ORDER BY sa.total_sales DESC) AS sales_rank_year
FROM sales_agg sa
ORDER BY sales_rank_year
LIMIT 100
