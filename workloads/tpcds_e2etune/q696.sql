SELECT
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    w.w_suite_number,
    agg.total_sales,
    agg.total_profit,
    agg.profit_margin,
    ib.avg_upper_bound,
    RANK() OVER (ORDER BY agg.total_sales DESC) AS sales_rank
FROM (
    SELECT
        ws.ws_warehouse_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE WHEN SUM(ws.ws_ext_sales_price) = 0 THEN 0
             ELSE SUM(ws.ws_net_profit) / SUM(ws.ws_ext_sales_price) END AS profit_margin
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
      AND ws.ws_quantity > 0
    GROUP BY ws.ws_warehouse_sk
) agg
JOIN warehouse w
    ON agg.ws_warehouse_sk = w.w_warehouse_sk
CROSS JOIN (
    SELECT AVG(ib_upper_bound) AS avg_upper_bound
    FROM income_band
) ib
WHERE w.w_country = 'United States'
  AND w.w_suite_number LIKE 'Suite %'
  AND agg.total_sales > 10000
ORDER BY agg.total_sales DESC
LIMIT 20
