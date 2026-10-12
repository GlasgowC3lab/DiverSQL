WITH ws_agg AS (
    SELECT
        i.i_category,
        td.t_hour,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_bill_cust,
        COUNT(DISTINCT ws.ws_ship_cdemo_sk) AS distinct_ship_demo
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    WHERE cd_bill.cd_gender = 'M'
    GROUP BY i.i_category, td.t_hour
),
sr_agg AS (
    SELECT
        i.i_category,
        td.t_hour,
        SUM(sr.sr_net_loss) AS total_returns,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_return_cust
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer_demographics cd_ret ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
    WHERE cd_ret.cd_marital_status = 'S'
    GROUP BY i.i_category, td.t_hour
),
inv_agg AS (
    SELECT
        i.i_category,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_category
)
SELECT
    COALESCE(ws.i_category, sr.i_category) AS category,
    COALESCE(ws.t_hour, sr.t_hour) AS hour_of_day,
    COALESCE(ws.total_sales, 0) AS total_sales,
    COALESCE(sr.total_returns, 0) AS total_returns,
    (COALESCE(ws.total_profit, 0) - COALESCE(sr.total_returns, 0)) AS net_profit,
    COALESCE(inv.avg_inventory, 0) AS avg_inventory,
    COALESCE(ws.distinct_bill_cust, 0) AS distinct_bill_cust,
    COALESCE(ws.distinct_ship_demo, 0) AS distinct_ship_demo,
    COALESCE(sr.distinct_return_cust, 0) AS distinct_return_cust,
    RANK() OVER (ORDER BY (COALESCE(ws.total_profit, 0) - COALESCE(sr.total_returns, 0)) DESC) AS profit_rank
FROM ws_agg ws
FULL OUTER JOIN sr_agg sr
    ON ws.i_category = sr.i_category AND ws.t_hour = sr.t_hour
LEFT JOIN inv_agg inv
    ON COALESCE(ws.i_category, sr.i_category) = inv.i_category
WHERE (COALESCE(ws.total_sales, 0) > 1000 OR COALESCE(sr.total_returns, 0) > 0)
ORDER BY net_profit DESC
LIMIT 100
