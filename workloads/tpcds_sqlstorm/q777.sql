SELECT c.c_customer_id, sum(ss.ss_net_paid) AS total_paid
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
GROUP BY c.c_customer_id
ORDER BY total_paid DESC
LIMIT 10
