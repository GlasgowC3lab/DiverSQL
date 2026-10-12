WITH customer_total AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
top_customers AS (
    SELECT ws_bill_customer_sk
    FROM customer_total
    ORDER BY total_profit DESC
    LIMIT 10
),
customer_monthly AS (
    SELECT
        ws.ws_bill_customer_sk,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_profit) AS monthly_profit,
        SUM(ws.ws_ext_sales_price) AS monthly_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(i.i_current_price) AS avg_item_price,
        w.web_state
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE ws.ws_bill_customer_sk IN (SELECT ws_bill_customer_sk FROM top_customers)
    GROUP BY ws.ws_bill_customer_sk, d.d_year, d.d_month_seq, w.web_state
)
SELECT
    cm.ws_bill_customer_sk,
    cm.d_year,
    cm.d_month_seq,
    cm.web_state,
    cm.monthly_profit,
    cm.monthly_sales,
    cm.total_quantity,
    cm.avg_item_price,
    CASE
        WHEN cm.monthly_profit >= 50000 THEN 'Platinum'
        WHEN cm.monthly_profit >= 20000 THEN 'Gold'
        WHEN cm.monthly_profit >= 10000 THEN 'Silver'
        ELSE 'Bronze'
    END AS profit_segment,
    SUM(cm.monthly_profit) OVER (PARTITION BY cm.ws_bill_customer_sk ORDER BY cm.d_year, cm.d_month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3month_profit,
    RANK() OVER (PARTITION BY cm.d_year ORDER BY cm.monthly_profit DESC) AS profit_rank_year
FROM customer_monthly cm
ORDER BY cm.monthly_profit DESC
LIMIT 20
