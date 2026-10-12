SELECT d.d_year,
       c.cc_name,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       COALESCE(SUM(cr.cr_return_amount), 0) AS total_returns,
       SUM(cs.cs_ext_sales_price) - COALESCE(SUM(cr.cr_return_amount), 0) AS net_sales
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center c ON cs.cs_call_center_sk = c.cc_call_center_sk
LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
WHERE d.d_year = 2000
GROUP BY d.d_year, c.cc_name
ORDER BY net_sales DESC
LIMIT 10
