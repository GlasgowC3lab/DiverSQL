SELECT cc.cc_name, SUM(cs.cs_net_paid) AS total_sales
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
GROUP BY cc.cc_name
ORDER BY total_sales DESC
LIMIT 10
