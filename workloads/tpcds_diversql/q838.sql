SELECT
  cc.cc_name,
  cc.cc_city,
  COUNT(DISTINCT cs.cs_order_number) AS order_count,
  SUM(cs.cs_ext_sales_price) AS total_sales
FROM tpcds.catalog_sales cs
JOIN tpcds.call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_company_name = 'ese'
  AND cs.cs_ext_list_price > 5000
GROUP BY cc.cc_name, cc.cc_city
ORDER BY total_sales DESC
LIMIT 10
