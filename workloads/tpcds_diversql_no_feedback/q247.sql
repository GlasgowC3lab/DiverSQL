WITH cs_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
        SUM(DISTINCT cs.cs_ext_sales_price) AS distinct_sales
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE
        sm.sm_type = 'AIR'
        AND td.t_hour BETWEEN 8 AND 12
        AND cs.cs_bill_customer_sk NOT IN (SELECT sr.sr_customer_sk FROM store_returns sr)
    GROUP BY cs.cs_bill_customer_sk
),
ws_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items,
        SUM(DISTINCT ws.ws_ext_sales_price) AS distinct_sales
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE
        sm.sm_type = 'AIR'
        AND td.t_hour BETWEEN 8 AND 12
        AND ws.ws_bill_customer_sk NOT IN (SELECT sr.sr_customer_sk FROM store_returns sr)
    GROUP BY ws.ws_bill_customer_sk
)
SELECT
    customer_sk,
    distinct_items,
    distinct_sales
FROM cs_agg
UNION ALL
SELECT
    customer_sk,
    distinct_items,
    distinct_sales
FROM ws_agg
ORDER BY distinct_sales DESC
LIMIT 100
