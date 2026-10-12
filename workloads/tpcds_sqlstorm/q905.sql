SELECT d.d_year,
       d.d_month_seq,
       sum(ss.ss_net_paid) AS total_net_paid
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 1999
GROUP BY d.d_year, d.d_month_seq
ORDER BY d.d_year, d.d_month_seq
