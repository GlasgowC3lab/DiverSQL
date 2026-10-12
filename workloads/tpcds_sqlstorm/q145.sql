SELECT c.c_customer_id, SUM(cs.cs_net_paid) AS total_spent
FROM customer c
JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
GROUP BY c.c_customer_id
ORDER BY total_spent DESC
LIMIT 10
