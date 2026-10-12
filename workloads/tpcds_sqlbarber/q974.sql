WITH ws_sub AS (
    SELECT ws_order_number, ws_sales_price
    FROM (
        SELECT ws_order_number,
               ws_sales_price,
               ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_sold_date_sk) AS rn
        FROM web_sales
        WHERE ws_sold_date_sk = 2451422
    ) t
    WHERE rn = 1
)
SELECT
    sm.sm_ship_mode_id,
    cs.cs_order_number,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(*) AS order_count,
    ws_sub.ws_sales_price AS sample_ws_sales_price
FROM catalog_sales cs
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
LEFT JOIN ws_sub
    ON ws_sub.ws_order_number = cs.cs_order_number
WHERE cs.cs_sold_date_sk = 2450847
GROUP BY sm.sm_ship_mode_id, cs.cs_order_number, ws_sub.ws_sales_price
HAVING sm.sm_ship_mode_id = 'AAAAAAAADAAAAAAA'
