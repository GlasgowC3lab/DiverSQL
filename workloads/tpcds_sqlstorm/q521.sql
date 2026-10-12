SELECT d.d_year,
       i.i_category,
       SUM(cs.cs_net_paid) AS total_net_paid,
       COUNT(*) AS order_count
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
GROUP BY d.d_year, i.i_category
ORDER BY total_net_paid DESC
LIMIT 10
