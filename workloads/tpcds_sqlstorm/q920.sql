SELECT c.c_customer_id, SUM(cs.cs_net_paid) AS total_sales
FROM catalog_sales cs
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY c.c_customer_id
ORDER BY total_sales DESC
LIMIT 10
