SELECT c.c_customer_id,
       SUM(cs.cs_ext_sales_price) AS total_spent
FROM catalog_sales cs
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY c.c_customer_id
ORDER BY total_spent DESC
LIMIT 10
