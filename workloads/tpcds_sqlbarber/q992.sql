SELECT cc.cc_name,
       SUM(cs.cs_net_paid) AS total_net_paid
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE cs.cs_sold_date_sk = 2450831
GROUP BY cc.cc_name
ORDER BY total_net_paid DESC
