SELECT s.s_store_name AS store_name,
       i.i_category AS category,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       SUM(ss.ss_net_profit) AS total_profit
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2000
GROUP BY s.s_store_name, i.i_category
ORDER BY total_sales DESC
LIMIT 10
