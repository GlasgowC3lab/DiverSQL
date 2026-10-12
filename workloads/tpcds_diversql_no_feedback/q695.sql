WITH filtered_web_sales AS (
   SELECT ws.ws_order_number,
          ws.ws_net_paid,
          ws.ws_sold_date_sk,
          ws.ws_ship_mode_sk,
          ws.ws_warehouse_sk,
          ws.ws_bill_customer_sk,
          ws.ws_bill_addr_sk,
          ws.ws_web_site_sk
   FROM web_sales ws
   WHERE ws.ws_sold_date_sk BETWEEN 2450541 AND 2452192
     AND ws.ws_net_paid > 0
)
SELECT
    cs.cs_order_number,
    cs.cs_net_paid,
    cs.cs_quantity,
    cc.cc_name,
    sm.sm_type,
    w.w_warehouse_name,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ws.ws_net_paid AS web_net_paid,
    RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY cs.cs_net_paid DESC) AS warehouse_sales_rank,
    CASE
        WHEN cs.cs_net_paid > 1000 THEN 'HIGH'
        ELSE 'LOW'
    END AS payment_category
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN filtered_web_sales ws
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
 AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site site
  ON ws.ws_web_site_sk = site.web_site_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
WHERE cc.cc_state = 'CA'
  AND sm.sm_contract = 'hGoF18SLDDPBj'
  AND w.w_state = 'TX'
  AND site.web_country = 'United States'
  AND c.c_birth_year BETWEEN 1960 AND 1970
  AND cs.cs_order_number NOT IN (
        SELECT ws2.ws_order_number
        FROM web_sales ws2
        WHERE ws2.ws_net_paid > 5000
    )
ORDER BY cs.cs_net_paid DESC
LIMIT 100
