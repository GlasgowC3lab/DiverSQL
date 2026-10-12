SELECT d.d_year, SUM(s.ss_net_paid) AS total_net_paid
FROM store_sales s
JOIN date_dim d ON s.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 1998
GROUP BY d.d_year
