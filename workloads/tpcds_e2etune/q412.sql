WITH bill_demo AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_warehouse_sk,
        cd.cd_credit_rating,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating IN ('Good', 'Low Risk')
      AND cd.cd_purchase_estimate >= 1500
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2459999
),
ship_demo AS (
    SELECT
        ws.ws_order_number,
        cd.cd_gender AS ship_gender
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_dep_employed_count > 0
),
agg AS (
    SELECT
        w.w_warehouse_name,
        bd.cd_credit_rating,
        bd.cd_marital_status,
        COUNT(DISTINCT bd.ws_order_number) AS orders,
        SUM(bd.ws_net_profit) AS total_profit,
        AVG(bd.ws_net_profit) AS avg_profit,
        MAX(CASE WHEN sd.ship_gender = 'F' THEN 1 ELSE 0 END) AS has_female_ship_demo
    FROM bill_demo bd
    JOIN ship_demo sd
        ON bd.ws_order_number = sd.ws_order_number
    JOIN warehouse w
        ON bd.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_name, bd.cd_credit_rating, bd.cd_marital_status
    HAVING COUNT(DISTINCT bd.ws_order_number) >= 10
)
SELECT
    a.w_warehouse_name,
    a.cd_credit_rating,
    a.cd_marital_status,
    a.orders,
    a.total_profit,
    a.avg_profit,
    a.has_female_ship_demo,
    RANK() OVER (PARTITION BY a.cd_credit_rating ORDER BY a.total_profit DESC) AS profit_rank
FROM agg a
ORDER BY a.total_profit DESC
LIMIT 50
