WITH cs_agg AS (
    SELECT
        t.t_hour AS hour_of_day,
        ca.ca_state AS state,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(cs.cs_quantity) AS catalog_qty,
        COUNT(*) AS catalog_orders
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450820 AND 2450826
    GROUP BY t.t_hour, ca.ca_state
),
ws_agg AS (
    SELECT
        t.t_hour AS hour_of_day,
        ca.ca_state AS state,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(ws.ws_quantity) AS web_qty,
        COUNT(*) AS web_orders
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450820 AND 2450826
    GROUP BY t.t_hour, ca.ca_state
)
SELECT
    cs_agg.hour_of_day,
    cs_agg.state,
    cs_agg.catalog_profit,
    ws_agg.web_profit,
    CASE WHEN cs_agg.catalog_profit > 0 THEN ws_agg.web_profit / cs_agg.catalog_profit END AS web_to_catalog_profit_ratio,
    cs_agg.catalog_qty,
    ws_agg.web_qty,
    cs_agg.catalog_orders,
    ws_agg.web_orders
FROM cs_agg
FULL OUTER JOIN ws_agg
    ON cs_agg.hour_of_day = ws_agg.hour_of_day
   AND cs_agg.state = ws_agg.state
WHERE cs_agg.catalog_profit IS NOT NULL
  AND ws_agg.web_profit IS NOT NULL
ORDER BY web_to_catalog_profit_ratio DESC
LIMIT 100
