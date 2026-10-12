WITH billed AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_ship_date_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        'bill' AS role
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_net_paid_inc_ship_tax > 2000
      AND c.c_current_cdemo_sk IN (1196373, 1185612)
),
shipped AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_ship_date_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        'ship' AS role
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_ship_customer_sk = c.c_customer_sk
    WHERE ws.ws_net_paid_inc_ship_tax < 3000
      AND c.c_last_review_date BETWEEN 2452360 AND 2452573
),
combined AS (
    SELECT * FROM billed
    UNION ALL
    SELECT * FROM shipped
),
small_dim AS (
    SELECT 1 AS dummy UNION ALL SELECT 2 UNION ALL SELECT 3
),
ranked AS (
    SELECT
        combined.c_customer_id,
        combined.c_first_name,
        combined.c_last_name,
        combined.ws_order_number,
        combined.ws_net_paid_inc_ship_tax,
        combined.role,
        small_dim.dummy,
        ROW_NUMBER() OVER (
            PARTITION BY combined.c_customer_id
            ORDER BY combined.ws_net_paid_inc_ship_tax DESC
        ) AS rn
    FROM combined
    CROSS JOIN small_dim
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    ws_order_number,
    ws_net_paid_inc_ship_tax,
    role,
    dummy
FROM ranked
WHERE rn <= 5
ORDER BY c_customer_id, rn
LIMIT 100
