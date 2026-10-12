WITH sales_union AS (
    SELECT
        cp.cp_department AS department,
        d.d_year AS year,
        cs.cs_bill_customer_sk AS customer_sk,
        SUM(cs.cs_net_paid) AS total_net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 1999
      AND cp.cp_department IN ('Books', 'Electronics')
    GROUP BY cp.cp_department, d.d_year, cs.cs_bill_customer_sk

    UNION ALL

    SELECT
        cp.cp_department AS department,
        d.d_year AS year,
        cs.cs_bill_customer_sk AS customer_sk,
        SUM(cs.cs_net_paid) AS total_net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2000
      AND cp.cp_department = 'Clothing'
    GROUP BY cp.cp_department, d.d_year, cs.cs_bill_customer_sk
)
SELECT
    department,
    year,
    SUM(total_net_paid) AS total_sales
FROM sales_union su
WHERE EXISTS (
    SELECT 1
    FROM web_page wp
    WHERE wp.wp_customer_sk = su.customer_sk
      AND wp.wp_type = 'Home'
)
GROUP BY department, year
ORDER BY total_sales DESC
