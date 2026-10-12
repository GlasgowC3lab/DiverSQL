SELECT cp.cp_department,
       ca.ca_state,
       SUM(cs.cs_net_paid) AS total_net_paid,
       AVG(cs.cs_quantity) AS avg_quantity
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
WHERE cs.cs_sold_date_sk = 2450836
  AND ca.ca_country = 'United States'
GROUP BY cp.cp_department, ca.ca_state
