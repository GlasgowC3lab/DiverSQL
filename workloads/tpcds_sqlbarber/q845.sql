SELECT ca.ca_state,
       sum(cs.cs_net_paid) AS total_catalog_sales,
       sum(ws.ws_net_paid) AS total_web_sales
FROM catalog_sales cs
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN web_sales ws ON ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE cs.cs_sold_date_sk = 2450855
  AND ws.ws_sold_date_sk = 2451973
GROUP BY ca.ca_state
