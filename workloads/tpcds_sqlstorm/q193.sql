SELECT c.c_customer_id, SUM(cs.cs_net_paid) AS total_spent
FROM catalog_sales cs
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
GROUP BY c.c_customer_id
ORDER BY total_spent DESC
LIMIT 10
