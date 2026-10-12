WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items,
        AVG(ws.ws_quantity) AS avg_quantity
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE
        sm.sm_code IN ('AIR', 'SEA')               -- filter 1: ship mode code
        AND w.web_state IN ('TX', 'CO')            -- filter 2: site state
        AND w.web_mkt_id = 5                       -- filter 3: market id
    GROUP BY
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        cd.cd_gender,
        cd.cd_marital_status
)
SELECT
    ws_web_site_sk,
    ws_ship_mode_sk,
    cd_gender,
    cd_marital_status,
    total_net_paid_inc_tax,
    distinct_orders,
    distinct_items,
    avg_quantity,
    ROW_NUMBER() OVER (ORDER BY total_net_paid_inc_tax DESC) AS rn
FROM sales_agg
WHERE total_net_paid_inc_tax > 10000                 -- additional filter on the aggregated result
ORDER BY total_net_paid_inc_tax DESC, rn
LIMIT 100
