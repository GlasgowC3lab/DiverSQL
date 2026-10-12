WITH monthly_ship_mode_profit AS (
    SELECT
        ws.ws_sold_date_sk AS date_key,
        sm.sm_carrier,
        sm.sm_type,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt,
        AVG(ws.ws_ext_discount_amt / NULLIF(ws.ws_ext_sales_price, 0)) AS avg_discount_rate
    FROM web_sales ws
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_carrier IN ('UPS', 'FEDEX', 'DHL')
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY ws.ws_sold_date_sk, sm.sm_carrier, sm.sm_type
)
SELECT
    date_key,
    sm_carrier,
    sm_type,
    total_profit,
    total_sales,
    order_cnt,
    avg_discount_rate,
    RANK() OVER (PARTITION BY date_key ORDER BY total_profit DESC) AS profit_rank
FROM monthly_ship_mode_profit
WHERE total_profit > 0
ORDER BY date_key, profit_rank
LIMIT 100
