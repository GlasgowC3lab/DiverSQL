SELECT d.d_date,
       i.i_category,
       SUM(ss.ss_net_paid) AS total_sales,
       SUM(ss.ss_net_profit) AS total_profit,
       AVG(ss.ss_quantity) AS avg_qty
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
WHERE d.d_year = 2001
GROUP BY d.d_date, i.i_category
ORDER BY d.d_date, i.i_category
