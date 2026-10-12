SELECT year,
       total_amount,
       source
FROM (
        SELECT d.d_year AS year,
               SUM(cs.cs_ext_sales_price) AS total_amount,
               'catalog' AS source
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        WHERE cp.cp_type = 'monthly'
          AND cs.cs_ext_sales_price > 1000
          AND cs.cs_bill_customer_sk IN (
                SELECT c2.c_customer_sk
                FROM customer c2
                WHERE c2.c_preferred_cust_flag = 'Y'
          )
        GROUP BY d.d_year
        UNION ALL
        SELECT d.d_year AS year,
               SUM(sr.sr_return_amt) AS total_amount,
               'store_return' AS source
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        WHERE s.s_state = 'CA'
          AND sr.sr_return_amt > 0
          AND sr.sr_customer_sk IN (
                SELECT c3.c_customer_sk
                FROM customer c3
                WHERE c3.c_preferred_cust_flag = 'Y'
          )
        GROUP BY d.d_year
     ) t
ORDER BY year,
         source
LIMIT 100
