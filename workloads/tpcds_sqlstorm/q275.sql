SELECT d.d_year,
       COUNT(*) AS order_cnt,
       SUM(ss.ss_net_paid) AS total_net_paid,
       SUM(ss.ss_ext_sales_price) AS total_ext_sales_price
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
GROUP BY d.d_year
ORDER BY d.d_year
