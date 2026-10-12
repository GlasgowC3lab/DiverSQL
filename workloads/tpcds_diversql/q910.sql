SELECT t.t_sub_shift,
       COUNT(*) AS order_cnt,
       SUM(cs.cs_net_profit) AS total_profit
FROM catalog_sales cs
JOIN time_dim t
  ON cs.cs_sold_time_sk = t.t_time_sk
WHERE t.t_sub_shift = 'morning'
  AND cs.cs_sales_price > 20
GROUP BY t.t_sub_shift
