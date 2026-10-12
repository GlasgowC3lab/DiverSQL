WITH high_sales AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_order_number   AS order_number,
        cs.cs_net_paid_inc_ship_tax AS amount,
        'catalog'            AS channel
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_net_paid_inc_ship_tax > 5000
    UNION ALL
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_order_number    AS order_number,
        ws.ws_net_paid_inc_ship_tax AS amount,
        'web'                 AS channel
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_net_paid_inc_ship_tax > 5000
)
SELECT
    hs.customer_sk,
    c.c_first_name,
    c.c_last_name,
    hs.amount,
    hs.channel
FROM high_sales hs
JOIN customer c ON hs.customer_sk = c.c_customer_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_order_number = hs.order_number
      AND cr.cr_return_quantity > 0
)
ORDER BY hs.amount DESC
LIMIT 100
