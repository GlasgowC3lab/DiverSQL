SELECT cc.cc_state,
       cc.cc_city,
       cc.cc_division_name,
       SUM(cs.cs_net_paid) AS total_sales,
       SUM(cs.cs_net_profit) AS total_profit,
       AVG(cs.cs_ext_discount_amt) AS avg_discount,
       COUNT(DISTINCT cs.cs_bill_customer_sk) AS unique_customers,
       (SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid), 0)) * 100 AS profit_margin_percent
FROM call_center cc
JOIN catalog_sales cs ON cc.cc_call_center_sk = cs.cs_call_center_sk
WHERE cc.cc_zip IN ('38828', '74536', '33451')
  AND cc.cc_division BETWEEN 2 AND 4
  AND cc.cc_employees > 3000000
  AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
GROUP BY cc.cc_state, cc.cc_city, cc.cc_division_name
HAVING SUM(cs.cs_net_paid) > 100000
ORDER BY total_sales DESC
LIMIT 100
