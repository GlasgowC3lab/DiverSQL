SELECT d.d_year,
       sum(ss.ss_net_paid) AS total_paid,
       sum(ss.ss_net_profit) AS total_profit
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 1998
GROUP BY d.d_year
