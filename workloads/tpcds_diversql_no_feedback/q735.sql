WITH catalog_part AS (
   SELECT
       cs.cs_bill_customer_sk AS customer_sk,
       SUM(cs.cs_net_profit) AS total_profit,
       CASE WHEN cs.cs_quantity > 5 THEN 'Large' ELSE 'Small' END AS order_size_category,
       w.w_warehouse_name AS warehouse_name
   FROM tpcds.catalog_sales cs
   JOIN tpcds.customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE ca.ca_state = 'CA'
     AND hd.hd_buy_potential = '>10000'
     AND cs.cs_list_price > 100
   GROUP BY cs.cs_bill_customer_sk,
            w.w_warehouse_name,
            CASE WHEN cs.cs_quantity > 5 THEN 'Large' ELSE 'Small' END
   HAVING SUM(cs.cs_net_profit) > 1000
),
web_part AS (
   SELECT
       ws.ws_bill_customer_sk AS customer_sk,
       SUM(ws.ws_net_profit) AS total_profit,
       CASE WHEN ws.ws_quantity > 5 THEN 'Large' ELSE 'Small' END AS order_size_category,
       w.w_warehouse_name AS warehouse_name
   FROM tpcds.web_sales ws
   JOIN tpcds.customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN tpcds.household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   WHERE ca.ca_state = 'NY'
     AND hd.hd_vehicle_count > 2
     AND ws.ws_list_price > 100
   GROUP BY ws.ws_bill_customer_sk,
            w.w_warehouse_name,
            CASE WHEN ws.ws_quantity > 5 THEN 'Large' ELSE 'Small' END
   HAVING SUM(ws.ws_net_profit) > 500
)
SELECT *
FROM (
   SELECT * FROM catalog_part
   UNION ALL
   SELECT * FROM web_part
) AS combined
WHERE customer_sk NOT IN (
   SELECT cs.cs_bill_customer_sk
   FROM tpcds.catalog_sales cs
   WHERE cs.cs_promo_sk = 9999
)
LIMIT 100
