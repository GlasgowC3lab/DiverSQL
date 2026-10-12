WITH full_sales_ret AS (
    SELECT 
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_net_paid,
        cs.cs_bill_customer_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
)
SELECT 
    c.c_first_name AS first_name,
    c.c_last_name AS last_name,
    f.cs_order_number AS order_number,
    f.cs_net_paid AS net_amount,
    'catalog' AS source
FROM full_sales_ret f
JOIN customer c
    ON f.cs_bill_customer_sk = c.c_customer_sk
WHERE f.cs_order_number IS NOT NULL
  AND f.cs_net_paid > 1000
UNION ALL
SELECT 
    c.c_first_name AS first_name,
    c.c_last_name AS last_name,
    ws.ws_order_number AS order_number,
    ws.ws_net_paid AS net_amount,
    'web' AS source
FROM web_sales ws
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE ws.ws_net_paid > 1000
ORDER BY net_amount DESC
LIMIT 100
