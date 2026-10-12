SELECT d.d_year,
       s.s_store_name,
       i.i_category,
       SUM(ss.ss_net_paid) AS total_net_paid,
       COUNT(*) AS sales_cnt
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
GROUP BY d.d_year, s.s_store_name, i.i_category
ORDER BY d.d_year, total_net_paid DESC
LIMIT 100
