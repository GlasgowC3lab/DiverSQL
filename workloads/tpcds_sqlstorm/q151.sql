SELECT d.d_year,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       COUNT(*) AS order_cnt
FROM store_sales ss
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1998 AND 2000
GROUP BY d.d_year
ORDER BY d.d_year
