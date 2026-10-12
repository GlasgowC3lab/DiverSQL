WITH cs_agg AS (
    SELECT
        sm.sm_type AS ship_mode_type,
        ca.ca_country AS country,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_catalog_customers,
        AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount,
        SUM(cs.cs_quantity) AS total_catalog_quantity
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_net_profit > 0
    GROUP BY sm.sm_type, ca.ca_country
),
ws_agg AS (
    SELECT
        sm.sm_type AS ship_mode_type,
        ca.ca_country AS country,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_web_customers,
        AVG(ws.ws_ext_discount_amt) AS avg_web_discount,
        SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ws.ws_net_profit > 0
    GROUP BY sm.sm_type, ca.ca_country
),
wr_agg AS (
    SELECT
        sm.sm_type AS ship_mode_type,
        ca.ca_country AS country,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(*) AS total_returns
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                     AND wr.wr_item_sk = ws.ws_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE wr.wr_net_loss > 0
    GROUP BY sm.sm_type, ca.ca_country
)
SELECT
    COALESCE(cs.ship_mode_type, ws.ship_mode_type, wr.ship_mode_type) AS ship_mode_type,
    COALESCE(cs.country, ws.country, wr.country) AS country,
    COALESCE(cs.total_catalog_profit, 0) AS total_catalog_profit,
    COALESCE(ws.total_web_profit, 0) AS total_web_profit,
    COALESCE(wr.total_return_loss, 0) AS total_return_loss,
    COALESCE(cs.distinct_catalog_customers, 0) + COALESCE(ws.distinct_web_customers, 0) AS total_distinct_customers,
    (
        COALESCE(cs.avg_catalog_discount, 0) * COALESCE(cs.total_catalog_quantity, 0) +
        COALESCE(ws.avg_web_discount, 0) * COALESCE(ws.total_web_quantity, 0)
    ) / NULLIF(COALESCE(cs.total_catalog_quantity, 0) + COALESCE(ws.total_web_quantity, 0), 0) AS weighted_avg_discount,
    COALESCE(cs.total_catalog_quantity, 0) + COALESCE(ws.total_web_quantity, 0) AS total_quantity,
    COALESCE(wr.total_returns, 0) AS total_returns
FROM cs_agg cs
FULL OUTER JOIN ws_agg ws
    ON cs.ship_mode_type = ws.ship_mode_type AND cs.country = ws.country
FULL OUTER JOIN wr_agg wr
    ON COALESCE(cs.ship_mode_type, ws.ship_mode_type) = wr.ship_mode_type
   AND COALESCE(cs.country, ws.country) = wr.country
WHERE (COALESCE(cs.total_catalog_profit, 0) + COALESCE(ws.total_web_profit, 0) - COALESCE(wr.total_return_loss, 0)) > 10000
ORDER BY total_web_profit DESC
LIMIT 50
