SELECT d.d_year,
       i.i_category,
       sum(ss.ss_net_paid) AS total_net_paid,
       sum(ss.ss_ext_sales_price) AS total_ext_sales,
       count(*) AS sales_cnt
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1998 AND 2002
GROUP BY d.d_year, i.i_category
ORDER BY d.d_year ASC, total_net_paid DESC
LIMIT 100
