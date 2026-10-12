WITH ws AS (
    SELECT
        ws.ws_bill_customer_sk AS cust_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND td.t_sub_shift = 'morning'
    GROUP BY ws.ws_bill_customer_sk
),
cr AS (
    SELECT
        cr.cr_refunded_customer_sk AS cust_sk,
        SUM(cr.cr_return_amount) AS total_return
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND td.t_sub_shift = 'morning'
    GROUP BY cr.cr_refunded_customer_sk
),
customers_no_return AS (
    SELECT cust_sk FROM ws
    EXCEPT
    SELECT cust_sk FROM cr
)
SELECT
    c.c_customer_id,
    ws.total_sales,
    CASE
        WHEN ws.total_sales > (SELECT AVG(total_sales) FROM ws) THEN 'High'
        ELSE 'Standard'
    END AS sales_category
FROM ws
JOIN customers_no_return cnr ON ws.cust_sk = cnr.cust_sk
JOIN customer c ON ws.cust_sk = c.c_customer_sk
WHERE EXISTS (
    SELECT 1
    FROM customer_address ca
    WHERE ca.ca_address_sk = c.c_current_addr_sk
      AND ca.ca_city = 'Seattle'
)
ORDER BY ws.total_sales DESC
LIMIT 100
