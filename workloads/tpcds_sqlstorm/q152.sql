SELECT d.d_year,
       i.i_category,
       SUM(ss.ss_net_paid) AS total_net_paid,
       COUNT(*) AS sales_count
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1999 AND 2002
GROUP BY d.d_year, i.i_category
ORDER BY d.d_year, total_net_paid DESC
