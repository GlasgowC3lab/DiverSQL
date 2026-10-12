WITH filtered AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_ext_list_price,
        cust.c_first_name,
        cust.c_last_name,
        cust.c_birth_month
    FROM tpcds.catalog_sales AS cs
    JOIN tpcds.customer AS cust
        ON cs.cs_bill_customer_sk = cust.c_customer_sk
    WHERE cust.c_birth_month = 2
      AND cs.cs_ext_list_price > 2000.00
)
SELECT
    c_birth_month,
    COUNT(*) AS orders_cnt,
    SUM(cs_ext_sales_price) AS total_sales
FROM filtered
GROUP BY c_birth_month
