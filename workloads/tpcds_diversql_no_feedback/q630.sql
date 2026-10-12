SELECT td.t_hour,
       SUM(cs.cs_net_paid_inc_ship) AS total_net_paid_inc_ship
FROM catalog_sales cs
JOIN time_dim td
  ON cs.cs_sold_time_sk = td.t_time_sk
WHERE cs.cs_net_paid_inc_ship > 3000
  AND td.t_hour = 14
GROUP BY td.t_hour
