WITH bill_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        CASE WHEN ws.ws_net_profit > 1000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY ws.ws_net_profit DESC) AS profit_rank_state
    FROM web_sales ws
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ca.ca_county = 'Maricopa County'
      AND ws.ws_ext_wholesale_cost > 2000
),
ship_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        CASE WHEN ws.ws_net_profit > 500 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY ws.ws_net_profit DESC) AS profit_rank_state
    FROM web_sales ws
    JOIN customer_address ca
        ON ws.ws_ship_addr_sk = ca.ca_address_sk
    WHERE ca.ca_county = 'Lipscomb County'
      AND ws.ws_ext_wholesale_cost > 1000
),
intersect_orders AS (
    SELECT ws_order_number FROM bill_sales
    INTERSECT
    SELECT ws_order_number FROM ship_sales
),
agg_sales AS (
    SELECT
        ws.ws_order_number,
        SUM(ws.ws_net_profit) AS total_profit,
        ca.ca_state
    FROM web_sales ws
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    GROUP BY ws.ws_order_number, ca.ca_state
)
SELECT
    COALESCE(io.ws_order_number, ag.ws_order_number) AS order_number,
    ag.total_profit,
    ag.ca_state,
    CASE WHEN ag.total_profit IS NULL THEN 'Missing' ELSE 'Present' END AS data_status,
    ROW_NUMBER() OVER (PARTITION BY ag.ca_state ORDER BY ag.total_profit DESC NULLS LAST) AS state_rank
FROM intersect_orders io
FULL OUTER JOIN agg_sales ag
    ON io.ws_order_number = ag.ws_order_number
ORDER BY state_rank
LIMIT 100
