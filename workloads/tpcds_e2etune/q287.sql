WITH sales_period AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        sm.sm_type,
        w.w_city,
        CASE
            WHEN ws.ws_sold_date_sk BETWEEN 2459000 AND 2459049 THEN DATE '2022-10-01'
            WHEN ws.ws_sold_date_sk BETWEEN 2459050 AND 2459099 THEN DATE '2022-11-01'
            ELSE DATE '2022-12-01'
        END AS period
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE sm.sm_type IN ('EXPRESS', 'OVERNIGHT')
      AND w.w_state = 'CA'
      AND ws.ws_ext_discount_amt > 50
)
SELECT
    sm_type,
    w_city,
    period,
    COUNT(DISTINCT ws_order_number) AS order_cnt,
    SUM(ws_quantity) AS total_qty,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_ext_discount_amt) AS total_discount,
    SUM(ws_net_profit) AS total_profit,
    SUM(ws_net_profit) / NULLIF(SUM(ws_ext_sales_price), 0) AS profit_margin
FROM sales_period
GROUP BY ROLLUP (sm_type, w_city, period)
HAVING SUM(ws_ext_sales_price) > 5000
ORDER BY total_profit DESC
LIMIT 200
