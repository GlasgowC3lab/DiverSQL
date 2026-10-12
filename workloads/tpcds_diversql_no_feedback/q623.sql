WITH ws_agg AS (
   SELECT
      ws_warehouse_sk,
      COUNT(*) AS order_cnt,
      SUM(ws_ext_sales_price) AS total_sales,
      AVG(ws_sales_price) AS avg_sales_price,
      MAX(ws_wholesale_cost) AS max_wholesale_cost
   FROM web_sales
   WHERE ws_ship_date_sk BETWEEN 2452288 AND 2452394
     AND ws_wholesale_cost > 50
     AND ws_wholesale_cost > (
         SELECT AVG(ws_wholesale_cost)
         FROM web_sales
         WHERE ws_ship_date_sk BETWEEN 2452288 AND 2452394
     )
   GROUP BY ws_warehouse_sk
)
SELECT
   w.w_warehouse_id,
   w.w_city,
   w.w_state,
   w.w_zip,
   ws_agg.order_cnt,
   ws_agg.total_sales,
   ws_agg.avg_sales_price,
   ws_agg.max_wholesale_cost,
   CASE WHEN ws_agg.max_wholesale_cost > 100 THEN 'High' ELSE 'Normal' END AS wholesale_category
FROM ws_agg
JOIN warehouse w
   ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
WHERE w.w_state = 'CA'
  AND w.w_zip LIKE '9%'
ORDER BY ws_agg.total_sales DESC
LIMIT 100
