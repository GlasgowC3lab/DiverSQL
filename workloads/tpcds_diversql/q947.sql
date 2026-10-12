WITH agg AS (
    SELECT
        ws.ws_warehouse_sk,
        d.d_year,
        hd.hd_income_band_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(ws.ws_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY CUBE (ws.ws_warehouse_sk, d.d_year, hd.hd_income_band_sk)
)
SELECT
    a.ws_warehouse_sk,
    a.d_year,
    a.hd_income_band_sk,
    a.total_profit,
    a.sales_cnt,
    a.profit_category
FROM agg a
WHERE a.profit_category = 'HIGH' AND a.total_profit > 20000
  AND NOT EXISTS (
        SELECT 1 FROM web_sales ws2
        WHERE ws2.ws_warehouse_sk = a.ws_warehouse_sk
          AND ws2.ws_net_profit > 100000
    )
EXCEPT
SELECT
    b.ws_warehouse_sk,
    b.d_year,
    b.hd_income_band_sk,
    b.total_profit,
    b.sales_cnt,
    b.profit_category
FROM agg b
WHERE b.profit_category = 'HIGH' AND b.total_profit > 50000
  AND NOT EXISTS (
        SELECT 1 FROM web_sales ws3
        WHERE ws3.ws_warehouse_sk = b.ws_warehouse_sk
          AND ws3.ws_net_profit > 100000
    )
LIMIT 100
