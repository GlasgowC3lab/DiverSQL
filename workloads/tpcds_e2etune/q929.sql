WITH ws_agg AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_ws_net_paid,
        SUM(ws.ws_net_profit) AS total_ws_net_profit,
        SUM(ws.ws_quantity) AS total_ws_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS ws_orders
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2452000 AND 2452600
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
sr_agg AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sr.sr_net_loss) AS total_sr_net_loss,
        SUM(sr.sr_return_amt) AS total_sr_return_amt,
        COUNT(*) AS sr_returns
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2452000 AND 2452600
      AND r.r_reason_desc LIKE '%defect%'
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT
    ws.cd_gender AS gender,
    ws.cd_marital_status AS marital_status,
    COUNT(DISTINCT ws.c_customer_sk) AS num_customers,
    COALESCE(SUM(ws.total_ws_net_profit), 0) AS total_web_profit,
    COALESCE(SUM(sr.total_sr_net_loss), 0) AS total_store_losses,
    COALESCE(SUM(ws.total_ws_net_profit), 0) - COALESCE(SUM(sr.total_sr_net_loss), 0) AS net_revenue,
    AVG(ws.total_ws_quantity) AS avg_quantity_per_customer,
    SUM(ws.ws_orders) AS total_web_orders,
    COALESCE(SUM(sr.sr_returns), 0) AS total_store_returns
FROM ws_agg ws
LEFT JOIN sr_agg sr
    ON ws.c_customer_sk = sr.c_customer_sk
GROUP BY ws.cd_gender, ws.cd_marital_status
ORDER BY net_revenue DESC
LIMIT 20
