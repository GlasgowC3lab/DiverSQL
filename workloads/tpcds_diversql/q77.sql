WITH store_part AS (
        SELECT c.c_customer_id AS customer_id,
               d.d_date AS sale_date,
               SUM(ss.ss_ext_sales_price) AS total_sales
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        WHERE d.d_year = 2002
        GROUP BY c.c_customer_id, d.d_date
    ),
    catalog_part AS (
        SELECT c.c_customer_id AS customer_id,
               d.d_date AS sale_date,
               SUM(cs.cs_ext_sales_price) AS total_sales
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        WHERE d.d_year = 2002
        GROUP BY c.c_customer_id, d.d_date
    ),
    union_sales AS (
        SELECT customer_id, sale_date, total_sales FROM store_part
        UNION ALL
        SELECT customer_id, sale_date, total_sales FROM catalog_part
    ),
    call_center_dates AS (
        SELECT cc.cc_call_center_sk,
               d.d_date AS open_date,
               cc.cc_name,
               cc.cc_market_manager
        FROM call_center cc
        JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
        WHERE d.d_year = 2002
    )
SELECT us.customer_id,
       us.sale_date,
       us.total_sales,
       cc.cc_name,
       cc.cc_market_manager
FROM union_sales us
FULL OUTER JOIN call_center_dates cc
    ON us.sale_date = cc.open_date
ORDER BY us.total_sales DESC
LIMIT 100
