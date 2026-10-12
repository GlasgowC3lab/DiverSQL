WITH union_data AS (
   SELECT
       cd.cd_demo_sk,
       cd.cd_gender,
       cd.cd_education_status,
       sm.sm_type,
       ss.ss_ext_sales_price AS store_sales_sum,
       ws.ws_ext_sales_price AS web_sales_sum,
       (ss.ss_ext_discount_amt + ws.ws_ext_discount_amt) AS total_discount,
       1 AS order_cnt,
       (SELECT MAX(ws3.ws_quantity) FROM web_sales ws3 WHERE ws3.ws_bill_cdemo_sk = cd.cd_demo_sk) AS max_quantity
   FROM store_sales ss
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN web_sales ws ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   RIGHT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE cd.cd_education_status = 'Advanced Degree'
     AND ss.ss_net_paid_inc_tax > 5000
     AND sm.sm_carrier = 'FedEx'
     AND EXISTS (
         SELECT 1 FROM web_sales ws2
         WHERE ws2.ws_ship_cdemo_sk = cd.cd_demo_sk
           AND ws2.ws_ext_discount_amt > 20
     )
   UNION DISTINCT
   SELECT
       cd.cd_demo_sk,
       cd.cd_gender,
       cd.cd_education_status,
       sm.sm_type,
       ss.ss_ext_sales_price AS store_sales_sum,
       ws.ws_ext_sales_price AS web_sales_sum,
       (ss.ss_ext_discount_amt + ws.ws_ext_discount_amt) AS total_discount,
       1 AS order_cnt,
       (SELECT MAX(ws3.ws_quantity) FROM web_sales ws3 WHERE ws3.ws_bill_cdemo_sk = cd.cd_demo_sk) AS max_quantity
   FROM store_sales ss
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN web_sales ws ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   RIGHT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE cd.cd_gender = 'F'
     AND ws.ws_ext_list_price > 20000
     AND sm.sm_carrier = 'UPS'
     AND ss.ss_coupon_amt > 1000
)
SELECT
    cd_gender,
    cd_education_status,
    sm_type,
    SUM(store_sales_sum) AS total_store_sales,
    SUM(web_sales_sum) AS total_web_sales,
    SUM(store_sales_sum + web_sales_sum) AS total_sales,
    AVG(total_discount) AS avg_discount,
    SUM(order_cnt) AS total_orders,
    MAX(max_quantity) AS max_quantity_across_orders
FROM union_data
GROUP BY cd_gender, cd_education_status, sm_type
ORDER BY total_sales DESC
LIMIT 100
