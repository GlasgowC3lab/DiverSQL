WITH billed AS (
   SELECT
       w.w_city,
       cd.cd_education_status,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       SUM(ws.ws_net_profit) AS total_profit,
       CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
       'Billed' AS source_type
   FROM web_sales ws
   JOIN customer_demographics cd
     ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN warehouse w
     ON ws.ws_warehouse_sk = w.w_warehouse_sk
   WHERE cd.cd_education_status = 'Advanced Degree'
     AND ws.ws_ext_sales_price > 1000
   GROUP BY w.w_city, cd.cd_education_status
),
shipped AS (
   SELECT
       w.w_city,
       cd.cd_education_status,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       SUM(ws.ws_net_profit) AS total_profit,
       CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
       'Shipped' AS source_type
   FROM web_sales ws
   JOIN customer_demographics cd
     ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
   JOIN warehouse w
     ON ws.ws_warehouse_sk = w.w_warehouse_sk
   WHERE cd.cd_education_status = 'Secondary'
     AND ws.ws_ext_sales_price > 500
   GROUP BY w.w_city, cd.cd_education_status
)
SELECT *
FROM billed
UNION ALL
SELECT *
FROM shipped
LIMIT 100
