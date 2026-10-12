SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cs.total_catalog_sales,
    SUM(ss.ss_net_paid) AS total_store_sales,
    (SELECT wr_inner.wr_return_amt
     FROM web_returns wr_inner
     WHERE wr_inner.wr_refunded_customer_sk = c.c_customer_sk
       AND wr_inner.wr_returned_date_sk = 2451577
     ORDER BY wr_inner.wr_returned_time_sk
     LIMIT 1) AS sample_return_amount
FROM
    customer c
    JOIN (
        SELECT
            cs.cs_bill_customer_sk AS cust_sk,
            SUM(cs.cs_net_paid) AS total_catalog_sales
        FROM
            catalog_sales cs
        WHERE
            cs.cs_sold_date_sk = 2450835
        GROUP BY
            cs.cs_bill_customer_sk
    ) cs
        ON cs.cust_sk = c.c_customer_sk
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
WHERE
    c.c_preferred_cust_flag = 'Y'
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cs.total_catalog_sales,
    c.c_customer_sk
HAVING
    SUM(ss.ss_net_paid) > 401.76
    AND cs.total_catalog_sales > 1
